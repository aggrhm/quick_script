require 'ostruct'

module QuickScript
  module Interaction

    ## HELPER ACTIONS
    
    def layout_only
      render :text => '', :layout => 'application'
    end

    protected

    class << self
      def included(base)
        base.send :extend, ClassMethods
      end
    end

    module ClassMethods
    end

    module Classes

      class RequestContext

        attr_accessor :actor, :selectors, :args, :limit, :page, :offset, :includes, :enhances, :sort
        attr_reader :params, :includes_tree, :enhances_tree

        def initialize(opts)
          if opts[:params]
            @params = opts[:params] || {}
            @actor = opts[:actor]
          else
            @params = opts
            @actor = opts[:request_actor] || opts[:actor]
          end
          @limit = 100
          @page = 1
          @offset = 0
          @includes = []
          @enhances = []
          @includes_tree = {}
          @enhances_tree = {}
          @enhances = []
          @selectors = {}
          if params[:scope]
            @selectors = QuickScript.parse_opts(params[:scope])
          end
          @limit = params[:limit].to_i if params[:limit]
          @page = params[:page].to_i if params[:page]
          @offset = (@page - 1) * @limit if params[:page] && params[:limit]
          self.includes = QuickScript.parse_opts(params[:includes]) if params[:includes]
          self.enhances = QuickScript.parse_opts(params[:enhances]) if params[:enhances]
          @sort = QuickScript.parse_opts(params[:sort]) if params[:sort]
        rescue => ex
          Rails.logger.info ex.message
          Rails.logger.info ex.backtrace.join("\n\t")
        end

        def selector_names
          @selectors.keys
        end

        def scope
          @selectors
        end

        def includes=(val)
          @includes = val || []
          @includes_tree = QuickScript.bool_tree(@includes)
        end
        def enhances=(val)
          @enhances = val || []
          @enhances_tree = QuickScript.bool_tree(@enhances)
        end

        # use this when need a subcontext hash
        def to_extended_params(opts=nil)
          opts ||= params
          ret = opts.merge(request_actor: actor, request_context: self)
          ret[:actor] ||= actor
          return ret
        end

        def to_opts(opts=nil)
          to_extended_params(opts)
        end

      end

      class ScopeResponder
        attr_reader :request_context, :options

        def initialize(request_context, opts={}, &block)
          @options = opts
          @request_context = request_context
          @names = {}.with_indifferent_access
          prepare
          block.call(self) if block
        end

        def prepare

        end

        def scopes
          @names
        end

        def scope_for_name(name)
          @names[name]
        end

        def base_scope
          options[:base_scope]
        end

        def base_selectors
          {}
        end

        def query_selectors
          base_selectors.merge(request_context.selectors)
        end

        def base_relation
          base_scope
        end

        def actor
          request_context.actor
        end

        def build_database_relation(opts={})
          crit = base_relation

          query_selectors.each do |k, v|
            ds = scope_for_name(k)

            if ds.nil? and options[:strict_scopes] != false
              raise QuickScript::Errors::APIError, "#{k} is not a valid scope"
            end
            next if ds.nil?

            if crit.nil?
              crit = ds.call(*v)
            else
              crit.merge!(ds.call(*v))
            end
          end
          return crit
        end

        def build_database_result
          ctx = request_context
          rel = build_database_relation
          params = request_context.params
          if params.key?(:id)
            data = rel.find(params[:id])
            ret = {success: data.present?, data: data}
          else
            data = rel.limit(ctx.limit).offset(ctx.offset).to_a
            count = rel.count
            pages_count = (count / ctx.limit.to_f).ceil
            if params.key?(:first)
              data = data.first
            elsif params.key?(:last)
              data = data.last
            end
            ret = {success: !data.nil?, data: data, count: count, pages_count: pages_count, page: ctx.page}
          end
          enhance_items(data.is_a?(Array) ? data : [data])
          return ret
        end

        def item(opts={})
          res = result(opts)
          res[:data]
        end

        def items(opts={})
          res = result(opts)
          res[:data]
        end

        def enhance_items(items)
          # use enhances here
        end

        def count
          res = result(opts)
          res[:count]
        end

        def build_result
          build_database_result
        end

        def result(opts={})
          if @result.nil? || opts[:reload]
            @result = build_result
          end
          return @result
        end

        def method_missing(method_sym, *args, &block)
          @names[method_sym.to_s] = block
        end

      end

      class ModelScopeResponder < ScopeResponder

        attr_reader :model

        def initialize(request_context, opts={}, &block)
          super(request_context, opts, &block)
          @model = opts[:model]

        end

        def base_scope
          self.model.all
        end

        def base_relation
          crit = base_scope
          incls = query_includes
          sort = query_sort
          # add includes
          if incls.present?
            crit = crit.includes(incls)
          end
          # add sort
          if sort.present?
            if crit.respond_to?(:order)
              crit = crit.order(sort)
            end
          end
          return crit
        end

        def allowed_query_includes
          # try to detect from relational model
          if model.respond_to?(:reflections)
            model.reflections.keys
          else
            []
          end
        end

        def allowed_query_sort_fields
          nil
        end

        def allowed_scope_names
          if options[:allowed_scope_names]
            ret = options[:allowed_scope_names]
          elsif model.const_defined?("PUBLIC_SCOPES")
            ret = model.const_get("PUBLIC_SCOPES")
          elsif model.respond_to?(:scope_names)
            ret = model.scope_names
          else
            ret = @names.keys
          end
          @allowed_scope_names = ret.collect(&:to_s)
        end

        def query_includes
          # go through allowed ones and see which are specified
          ta = QuickScript.bool_tree(allowed_query_includes || [])
          ti = QuickScript.bool_tree(request_context.includes || [])
          inter = QuickScript.bool_tree_intersection(ta, ti)
          return QuickScript.bool_tree_to_array(inter)
        end

        def query_sort
          # eventually use allowed_query_sort_fields
          sort = request_context.sort
          return nil if sort.blank?
          sort = sort.strip
          nsm = model.const_defined?("NAMED_SORTS") ? model.const_get("NAMED_SORTS") : {}
          # validate sort
          if (ns = nsm[sort]).present?
            # handle named sort
            sort = ns
          else
            validate_custom_sort!(sort)
          end
          return sort
        end

        def validate_custom_sort!(sort)
          parts = sort.split(/\s+/).collect(&:downcase)
          raise "Invalid sort #{sort}: Too long" if parts.length > 2
          raise "Invalid sort #{sort}: Must end with asc/desc" if parts[-1] != "asc" && parts[-1] != "desc"
        end

        def scope_for_name(name)
          asns = allowed_scope_names
          if asns && !asns.include?(name.to_s)
            return nil
          end
          return @names[name] if @names[name]
          return model.method(name.to_sym) if model.respond_to?(name.to_sym)
          return nil
        end

      end

    end
    include Classes

    def json_resp(data, meta=true, opts = {})
      meta = 200 if meta == true 
      meta = 404 if meta == false 
      opts[:data] = data
      opts[:meta] = meta
      opts[:success] = meta == 200

      if meta != 200 && opts[:error].blank?
        opts[:error] = "An error occurred"
      end
      opts.to_json
    end

    def params_with_actor
      if self.respond_to?(:current_user, true)
        return params.merge(actor: self.current_user)
      else
        return params
      end
    end

    def params_with_context
      request_context.to_extended_params
    end

    def request_includes(sub=nil)
      incs = params[:include] || params[:includes]
      if incs
        rs = JSON.parse(incs).collect(&:to_s)
        if sub
          sub = sub.to_s
          sl = sub.length + 1
          rs = rs.select{|r| r.start_with?(sub + ".")}.collect{|r| r[(sl..-1)]}
        end
        # only top level
        return rs.select{|r| !r.include?(".")}.collect(&:to_sym)
      else
        return []
      end
    end
    def requested_includes(sub=nil)
      request_includes(sub)
    end

    def json_error(errors, meta = 404, opts = {})
      json_resp({:errors => errors}, meta, {error: errors[0]})
    end

    def render_data(data, meta=true, opts={})
      render :json => json_resp(data, meta, opts)
    end

    def render_error(err)
      render :json => json_error([err])
    end

    # Called as part of render_result. Serializes the individual
    # fields of the result to prepare it for transmission to the
    # client.
    #
    # Per field manipulations can be inserted by overriding
    # prepare_api_field in your controller.
    #
    # @param [Hash] result to serialize
    # @param [Hash] parameters that will be provided to object transformers (typically your model's to_api method)
    # @return [Hash] json compatible serialized result
    def prepare_result(result, opts={})
      ret = {}
      result.each do |key, val|
        ret[key] = prepare_api_field(key, val)
      end
      return ret
    end

    # Prepare an individual field in the result object for
    # serialization. This is an appropriate place to insert
    # transformations over the entire contents of a field whereas
    # api_object_transformers is more appropriate for transforming
    # each member of the field individually.
    #
    # By default this method performs no transformation and exists
    # only to be overridden.
    #
    # @param [String] name of the field
    # @param [Hash, Model, String, ...] 
    def prepare_api_field(key, val)
      opts = {includes: request_context.includes_tree, actor: request_context.actor, request_actor: request_context.actor, request_context: request_context}
      if val.is_a?(Array)
        opts = opts.merge(embedded: true)
        return val.collect {|v| prepare_api_object(v, opts)}
      else
        return prepare_api_object(val, opts)
      end
    end

    def prepare_api_object(model, opts={})
      if model.respond_to?(:to_api)
        model.to_api(opts)
      else
        model
      end
    end

    def render_result(result, opts = {}, &block)
      result = self.prepare_result(result, opts)

      resp = OpenStruct.new
      opts[:include_all] = true if opts[:include_all].nil?
      # set required fields
      resp.success = result[:success]
      resp.meta = result[:meta] || (result[:success] ? 200 : 500)
      resp.error = result[:error]

      # prepare data
      if !((data = result[:data]).nil?)
        resp.data = QuickScript.prepare_api_param(data)
      end

      # prepare additional fields
      result.each do |key, val|
        next if [:success, :meta, :data, :error].include?(key.to_sym)
        next if opts[:include] && !opts[:include].include?(key.to_sym)
        resp[key] = QuickScript.prepare_api_param(val)
      end

      block.call(resp) unless block.nil?

      resp_h = resp.marshal_dump
      status = opts[:status] || resp.meta

      render :json => resp_h.to_json, :status => status
    end

    def handle_params
      # handle api_ver
      @api_version = request.headers['API-Version'] || 0
      ENV['API_VER'] = @api_version.to_s
    end

    def request_context
      @request_context ||= begin
        actor = self.respond_to?(:current_user, true) ? current_user : nil
        QuickScript::RequestContext.new(params: params.to_unsafe_h, actor: actor)
      end
    end

    def get_scoped_items(model, scope, limit, offset)
        @items = model
        scope.each do |m, args|
          # validate scope
          next unless can? m.to_sym, model
          args = [current_user.id.to_s] if m.include?("my_") && current_user
          if args == []
            @items = @items.send(m)
          else
            @items = @items.send(m, *args)
          end
        end
        return [] if @items == model
        @items = @items.limit(limit).offset(offset)
    end

    def respond_to_scope(resp_action=:items, responder=nil, &block)
      responder ||= ScopeResponder.new(request_context, &block)
      responder.send(resp_action)
    end

  end
end

class Hash

  def extend_with_request_context(opts)
    opts[:params] = self
    rc = QuickScript::RequestContext.new(opts)
    return rc.to_extended_params
  end

end
