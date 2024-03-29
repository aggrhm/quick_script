module QuickScript

  module Model

    def self.included(base)
      base.send :extend, ClassMethods
      if defined?(ActiveRecord) && base < ActiveRecord::Base
        base.send :extend, ActiveRecordClassMethods
      end
    end

    module ClassMethods

      def enum_methods!(name, enum_map)
        orig_enum_map = enum_map
        enum_map = enum_map.with_indifferent_access
        name = name.to_s
        define_method "#{name}?" do |opt|
          val = send(name)
          if opt.is_a?(Array)
            return opt.collect{|a| enum_map[a]}.include? val
          else
            return val == enum_map[opt] || val == opt.to_s.to_i
          end
        end
        define_method "#{name}!" do |opt|
          # determine value
          if opt.blank?
            val = nil
          else
            val = enum_map[opt]
            val = opt.to_s.to_i if val.nil?
            raise "Value #{opt} not found for #{name}" if !enum_map.values.include?(val)
          end
          send("#{name}=", val)
          if self.respond_to? "#{name}_changed_at"
            send("#{name}_changed_at=", Time.now)
          end
          val
        end
        define_method "#{name}_key" do
          val = send(name)
          orig_enum_map.invert[val]
        end
      end

      def scope_responder(ctx, opts={})
        opts[:model] ||= self
        if defined?(self::ScopeResponder)
          cls = self::ScopeResponder
        else
          cls = QuickScript::ModelScopeResponder
        end
        cls.new(ctx, opts)
      end

      def index_as_action!(opts)
        ctx = opts[:request_context] || QuickScript::RequestContext.new(opts)
        res = scope_responder(ctx).result
        return res
      end

      def create_as_action!(opts)
        m = self.new
        res = m.update_as_action!(opts)
        return res
      end

      def scope_names
        return @scope_names ||= []
      end

      def scope(name, body, &block)
        ret = super(name, body, &block)
        scope_names << name
        return ret
      end

      def raise_api_error(err)
        raise QuickScript::APIError.new(err)
      end

    end

    module ActiveRecordClassMethods

      def embeds_one(name, opts)
        if defined?(SchemaSync) && self.included_modules.include?(SchemaSync::Model)
          field name.to_sym, type: Hash
        end

        define_method name do
          src = self[name]
          cls = opts[:class_name].constantize
          if src
            return cls.from_parent(self, src)
          else
            if opts[:autobuild]
              if self.destroyed?
                return cls.from_parent(self, {})
              else
                self[name] = {}
                return cls.from_parent(self, self[name])
              end
            else
              return nil
            end
          end
        end

        define_method "#{name}=" do |val|
          if val == nil
            self[name] = nil
          else
            if val.is_a?(Hash)
              self[name] = val
            else
              self[name] = val.attributes
              val.set_parent(self, self[name])
            end
          end
          return val
        end
      end

    end


    # INSTANCE METHODS

    def update_fields_from(data, fields, options={})
      fields.each do |field|
        if data.key?(field)
          val = data[field]
          if options[:strip] != false
            val = val.strip if val.respond_to?(:strip)
          end
          self.send "#{field.to_s}=", val
        end
      end
    end

    def error_message
      self.error_messages.first
    end

    def error_messages
      self.errors.messages.values.flatten
    end

    def has_present_association?(assoc)
      self.association(assoc).loaded? && self.send(assoc).present?
    end

    def raise_api_error(err)
      raise api_error(err)
    end

    def api_error(msg)
      return QuickScript::APIError.new(msg)
    end

    def associations_to_api(assocs, opts={})
      ret = {}
      incl = opts[:includes] || {}
      assocs.each do |assoc|
        if incl[assoc.to_s]
          val = self.send(assoc)
          aopts = opts.merge(embedded: true, includes: incl[assoc.to_s])
          ret[assoc.to_sym] = val ? val.to_api(aopts) : nil
        end
      end
      return ret
    end

  end

end
