module QuickScript

  module Model

    def self.included(base)
      base.send :extend, ClassMethods
      if defined?(ActiveRecord) && base < ActiveRecord::Base
        base.send :extend, ActiveRecordClassMethods
      end
    end

    module ClassMethods

      def enum_methods!(enum, opts)
        enum = enum.to_s
        define_method "#{enum}?" do |opt|
          val = send(enum)
          if opt.class == Array
            return opt.collect{|a| opts[a]}.include? val
          else
            return val == opts[opt]
          end
        end
        define_method "#{enum}!" do |opt|
          send("#{enum}=", opts[opt])
          if self.respond_to? "#{enum}_changed_at"
            send("#{enum}_changed_at=", Time.now)
          end
        end
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
              self[name] = {}
              return cls.from_parent(self, self[name])
            else
              nil
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

  end

end
