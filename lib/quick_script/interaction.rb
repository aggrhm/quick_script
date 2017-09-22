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

        attr_accessor :selectors, :args, :limit, :page, :offset, :includes, :enhances, :sort
        attr_reader :params, :includes_tree, :enhances_tree

        def initialize(params)
          @params = params
          @limit = 100
          @page = 1
          @offset = 0
          @includes = []
          @enhances = []
          @includes_tree = {}
          @enhances_tree = {}
          @enhances = []
          if params[:scope]
            @selectors = JSON.parse(params[:scope])
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

        def actor
          return @params[:actor]
        end

        def selector_names
          @selectors.keys
        end

        def includes=(val)
          @includes = val || []
          @includes_tree = QuickScript.bool_tree(@includes)
        end
        def enhances=(val)
          @enhances = val || []
          @enhances_tree = QuickScript.bool_tree(@enhances)
        end

      end

      class ScopeResponder
        attr_reader :request_context, :criteria

        def initialize(request_context, opts={}, &block)
          @options = opts
          @request_context = request_context
          @names = {}.with_indifferent_access
          block.call(self) if block
          update_criteria
        end

        def scopes
          @names
        end

        def scope_for_name(name)
          @names[name]
        end

        def base_scope
          @options[:base_scope]
        end

        def base_criteria
          crit = base_scope
        end

        def actor
          request_context.actor
        end

        def update_criteria(opts={})
          crit = base_criteria

          request_context.selectors.each do |k, v|
            ds = scope_for_name(k)

            if ds.nil? and @options[:strict_scopes]
              raise QuickScript::Errors::APIError, "#{k} is not a valid scope"
            end
            next if ds.nil?

            if crit.nil?
              crit = ds.call(*v)
            else
              crit.merge!(ds.call(*v))
            end
          end
          @criteria = crit
        end

        def item
          ctx = request_context
          itm = criteria.find(ctx.params[:id])
          return itm
        end

        def items
          ctx = request_context
          crit = criteria
          return [] if crit.nil?
          if crit.respond_to? :limit
            items = crit.limit(ctx.limit).offset(ctx.offset).to_a
          else
            items = crit[ctx.offset..(ctx.offset + ctx.limit)]
          end
          return items
        end

        def count
          crit = criteria
          return 0 if crit.nil?
          crit.count
        end

        def result(opts={})
          ctx = request_context
          count = self.count
          if count > 0
            data = self.items
          else
            data = []
          end
          if ctx.limit > 0
            pages_count = (count / ctx.limit.to_f).ceil
          else
            pages_count = 0
          end
          return {success: true, data: data, count: count, pages_count: pages_count, page: ctx.page}
        end

        def method_missing(method_sym, *args, &block)
          @names[method_sym.to_s] = block
        end

      end

      class ModelScopeResponder < ScopeResponder

        attr_reader :model

        def initialize(request_context, model, opts={}, &block)
          @model = model

          if opts[:allowed_scope_names]
            @allowed_scope_names = opts[:allowed_scope_names].collect(&:to_s)
          elsif @model.const_defined?("PUBLIC_SCOPES")
            @allowed_scope_names = @model.const_get("PUBLIC_SCOPES").collect(&:to_s)
          else
            @allowed_scope_names = nil
          end
          super(request_context, opts, &block)
        end

        def base_scope
          self.model.all
        end

        def base_criteria
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

        def query_includes
          # go through allowed ones and see which are specified
          ta = QuickScript.bool_tree(allowed_query_includes || [])
          ti = QuickScript.bool_tree(request_context.includes || [])
          inter = QuickScript.bool_tree_intersection(ta, ti)
          return QuickScript.bool_tree_to_array(inter)
        end

        def query_sort
          # eventually use allowed_query_sort_fields
          request_context.sort
        end

        def scope_for_name(name)
          if @allowed_scope_names && !@allowed_scope_names.include?(name.to_s)
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
      if val.is_a?(Array)
        return val.collect {|v| prepare_api_object(v, embedded: true)}
      else
        return prepare_api_object(val)
      end
    end

    def prepare_api_object(model, opts={})
      if model.respond_to?(:to_api)
        model.to_api(opts.merge(includes: request_context.includes_tree, actor: request_context.actor, request_context: request_context))
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
      @request_context ||= QuickScript::RequestContext.new(params_with_actor)
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
