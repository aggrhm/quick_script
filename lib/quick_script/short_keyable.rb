module QuickScript

  module ShortKeyable

    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods

      def short_keyable!
        field :short_key, type: String
        before_validation :ensure_short_key
      end

      def short_key_options
        @short_key_options ||= {}
        @short_key_options[:chars] ||= [('a'..'z').to_a, ('A'..'Z').to_a].flatten - ['l', 'O']
        @short_key_options[:length] ||= 8
        return @short_key_options
      end

      def configure_short_key_options(opts)
        short_key_options.merge!(opts)
      end

      def generate_short_key
        opts = self.short_key_options
        return opts[:chars].flatten.shuffle[0, opts[:length]].join
      end

    end

    def ensure_short_key
      if self.short_key.blank?
        loop do
          k = self.class.generate_short_key
          if self.class.find_by_short_key(k).nil?
            self.short_key = k
            break
          end
        end 
      end
    end

  end

end

