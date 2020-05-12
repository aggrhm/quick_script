module QuickScript

  module ModelEndpoints

    def self.included(base)
      base.extend ClassMethods
      base.before_action :prepare_request_context
      class << base
        #private :scope_responder
        #private :prepare_model
        #private :load_model
      end
    end

    module ClassMethods
      def model_endpoints_settings
        @model_endpoints_settings ||= {
          model_class_name: nil,
          default_includes: [],
          use_orm_includes: false,
          default_result_options: {},
          scope_responder: lambda {|scope| },
          endpoints: {
            save: {
              instantiate_if_nil: true,
              model_method: QuickScript.config.default_model_save_method
            },
            delete: {
              model_method: QuickScript.config.default_model_delete_method
            },
          }
        }.with_indifferent_access
      end

      def configure_model_endpoints_for(name, opts={})
        model_endpoints_settings[:model_class_name] = name
        model_endpoints_settings[:use_orm_includes] = true if model_class_orm == :active_record
        model_endpoints_settings.deep_merge!(opts)
        # clean endpoints
        model_endpoints_settings[:endpoints].keys.each do |name|
          opts = model_endpoints_settings[:endpoints][name]
          if !opts.is_a?(Hash)
            model_endpoints_settings[:endpoints][name] = {model_method: opts.to_sym}
          end
        end
        build_model_endpoints
      end

      def model_class
        model_endpoints_settings[:model_class_name].constantize
      end

      def model_class_orm
        if defined?(ActiveRecord) && model_class < ActiveRecord::Base
          return :active_record
        elsif model_class.respond_to?(:mongo_session)
          return :mongoid
        end
      end

      def add_model_endpoint(method, model_method, opts={})
        opts.merge!(name: method, model_method: model_method)
        model_endpoints_settings[:endpoints][method] = opts
        build_model_endpoint(opts)
      end

      def build_model_endpoints
        model_endpoints_settings[:endpoints].each do |name, opts|
          opts[:name] = name
          next if [:index].include?(name.to_sym)
          #puts "Defining method for #{name}"
          build_model_endpoint(opts)
        end
      end

      def build_model_endpoint(opts)
        name = opts[:name]
        define_method name do
          mes = self.class.model_endpoints_settings
          mopts = mes[:endpoints][name]
          if mopts[:model_class_method].present?
            res = model_class.send mopts[:model_class_method], request_context.to_extended_params
          else
            # load model
            if (mopts[:instantiate_if_nil] == true) && model_instance.nil?
              self.model_instance = model_class.new
            end
            res = model_instance.send mopts[:model_method], request_context.to_extended_params
          end
          if mopts[:prepare_result]
            self.instance_exec(res, &mopts[:prepare_result])
          end
          ropts = mes[:default_result_options].merge( (mopts[:result_options] || {}) )
          render_result(res, ropts.merge(action: name.to_sym))
        end
      end

    end # END CLASS METHODS

    def model_endpoints_settings
      self.class.model_endpoints_settings
    end

    def model_class
      self.class.model_class
    end

    def model_instance=(val)
      @model = val
    end

    def model_instance
      @model || load_model_instance
    end

    def index
      if model_class.respond_to?(:index_as_action!)
        res = model_class.send :index_as_action!, request_context.to_extended_params
      else
        res = scope_responder.result
      end
      prepare_model(res[:data]) # deprecated, use scope_responder enhance_items
      render_result(res, action: :index)
    end

    ## PRIVATE METHODS

    def scope_responder
      @scope_responder ||= begin
        opts = {model: model_class}
        if defined?(model_class::ScopeResponder)
          cls = model_class::ScopeResponder
        else
          cls = QuickScript::ModelScopeResponder
        end
        cls.new(request_context, opts)
      end
    end

    def model_includes
      incls = requested_includes | self.class.model_endpoints_settings[:default_includes]
    end

    def prepare_request_context
      request_context.includes = request_context.includes | (self.model_endpoints_settings[:default_includes] || [])
    end

    def prepare_model(models)
      if model_endpoints_settings[:use_orm_includes] == false
        model_class.update_cache(models, model_includes) if model_class.respond_to?(:update_cache)
      end
    end

    def load_model_instance
      if params[:id].present?
        @model = scope_responder.item
        raise QuickScript::Errors::ResourceNotFoundError if @model.nil?
      end
      return @model
    end

  end

end
