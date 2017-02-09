module QuickScript

  module Eventable

    def self.included(base)
      base.send :extend, ClassMethods
    end

    module ClassMethods
      def event_handlers
        @event_handlers ||= []
      end

      def handle_event(ev, method, eopts={})
        event_handlers << eopts.merge({event: ev, method: method})
      end

      def handle_event_as_callback(ev, method, eopts={})
        eopts[:callback] = true
        handle_event(ev, method, eopts)
      end
    end

    def report_event(ev, opts={})
      self.handle_event_as_callback(ev, opts)
      begin
        rex = false
        self.handle_event_internally(ev, opts)
        self.handle_event(ev, opts)
        handlers = self.class.event_handlers.select {|eh| eh[:event].to_s == ev.to_s}
        handlers.each do |eh|
          rex = eh[:callback] == true
          self.send(eh[:method], opts)
        end
      rescue => ex
        if defined?(Rails)
          Rails.logger.info(ex.message)
          Rails.logger.info(ex.backtrace.join("\n\t"))
        end
        raise if rex
      end
    end

    def handle_event_internally(ev, opts)
    end

    def handle_event(ev, opts)
      # override this in class
    end

    def handle_event_as_callback(ev, opts)
    end

  end

end
