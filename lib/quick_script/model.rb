module QuickScript

  module Model

    def self.included(base)
      base.send :extend, ClassMethods
    end

    module ClassMethods
      def attr_alias(new_attr, old_attr)
        alias_method(new_attr, old_attr)
        alias_method("#{new_attr}=", "#{old_attr}=")
      end

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

    # INSTANCE METHODS

    def error_message
      self.error_messages.first
    end

    def error_messages
      self.errors.messages.values.flatten
    end

  end

end
