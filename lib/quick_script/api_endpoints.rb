module QuickScript

  module ApiEndpoints

    def self.included(base)
      base.send :include, QuickScript::Interaction
      base.extend ClassMethods
    end

    def self.mounts
      @mounts ||= {}
    end

    def self.configure(path, opts={}, &block)
      mount = EndpointMount.new(path, opts)
      mount.instance_exec(&block)
      mounts[path] = mount
    end

    class EndpointMount

      attr_reader :controller, :path, :endpoints

      def initialize(path, opts)
        @path = path
        @name = opts[:name]
        @controller = opts[:controller] || "api"
        @class_name = opts[:class_name]
        @endpoints = {}
        @options = opts
        @endpoint_options = {mount: self, class_name: opts[:class_name]}
      end

      def model_endpoints_for(model, opts={}, &block)
        ms = model.to_s.underscore
        mp = ms.pluralize
        #puts "Adding route for #{rp}"
        ep = EndpointBuilder.new(mount: self, class_name: model)
        ep.get mp, class_name: model, class_action: QuickScript.config.default_model_index_method
        ep.post ms, class_name: model, action: QuickScript.config.default_model_save_method, instantiate_if_nil: true
        ep.delete ms, class_name: model, action: QuickScript.config.default_model_delete_method
        ep.instance_exec(&block) if block
      end

    end

    class EndpointBuilder

      def initialize(opts)
        @mount = opts[:mount]
        @endpoint_options = {class_name: opts[:class_name]}
      end

      def post(path, opts)
        add_endpoint(:post, path, opts)
      end

      def get(path, opts)
        add_endpoint(:get, path, opts)
      end

      def delete(path, opts)
        add_endpoint(:delete, path, opts)
      end

      def add_endpoint(method, path, opts)
        method = method.to_sym
        key = [method, File.join(@mount.path, path)]
        opts[:method] = method
        opts[:path] = path
        @mount.endpoints[key] = @endpoint_options.merge(opts)
      end

    end

    module ClassMethods

    end

    def model_class
      @model_class ||= @endpoint[:class_name].constantize
    end

    def handle_api_request
      # determine mount
      mp = params[:qs_api_mount_path]
      @mount = QuickScript::ApiEndpoints.mounts[mp]
      # determine endpoint
      method = request.method.downcase.to_sym
      path = request.path
      #puts path
      @endpoint = @mount.endpoints[ [method, path] ]
      res = call_endpoint_action(@endpoint)
      # call endpoint method
      render_result(res)
    end

    def call_endpoint_action(endpoint)
      if endpoint[:class_action].present?
        Rails.logger.info "Endpoint: #{endpoint[:class_name]}.#{endpoint[:class_action]}"
        res = model_class.send endpoint[:class_action], request_context.to_extended_params
      else
        # load model
        load_model_instance
        if (endpoint[:instantiate_if_nil] == true) && @model.nil?
          @model = model_class.new
        end
        Rails.logger.info "Endpoint: #{endpoint[:class_name]}.#{endpoint[:action]}"
        res = @model.send endpoint[:action], request_context.to_extended_params
      end
      return res
    end

    def model_scope_responder
      @model_scope_responder ||= begin
        opts = {model: model_class}
        if defined?(model_class::ScopeResponder)
          cls = model_class::ScopeResponder
        else
          cls = QuickScript::ModelScopeResponder
        end
        cls.new(request_context, opts)
      end
    end

    def load_model_instance
      if params[:id].present?
        @model = model_scope_responder.item
        raise QuickScript::Errors::ResourceNotFoundError if @model.nil?
      end
      return @model
    end

  end

end
