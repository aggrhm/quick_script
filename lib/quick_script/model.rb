module QuickScript

  module Model

    def self.included(base)
      base.send :extend, ClassMethods
    end

    # creates the instance bound to self of the anonymous "actions"
    # class that resulted from the calls to def_action
    def actions
      @actions ||= self.class.actions_class.new(self)
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

      # class created once per mixin to contain all of the methods
      # created using def_action
      def actions_class
        @actions_class ||= Class.new do
          attr_reader :target

          define_method(:initialize) do |target|
            @target = target
          end
        end
      end

      # create an action inside the actions_class that wraps the body
      # and returns the standard dictionary reply required for an
      # action
      def def_action(method_name, &block)
        actions_class.class_eval do
          define_method(method_name) do |*args|
            begin
              result = self.target.instance_exec(*args, &block)
              {success: true, data: result}
            rescue => ex
              {success: false, reason: ex}
            end
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
