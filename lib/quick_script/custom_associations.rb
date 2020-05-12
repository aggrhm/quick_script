module QuickScript

  module CustomAssociations

    def self.included(base)
      base.send :extend, ClassMethods
    end

    module ClassMethods

      def load_custom_association(models, assoc_key, opts)
        assoc_key = assoc_key.to_sym
        opts[:enhance] ||= lambda {|m, em|
          m.cache_custom_association assoc_key, em
        }
        QuickScript.enhance_models(models, opts)

        # set custom association to nil if not set
        models.each do |m|
          if !m.custom_association_cached?(assoc_key)
            m.cache_custom_association(assoc_key, nil) 
          end
        end
        return models
      end

    end ## END CLASSMETHODS

    def custom_association_cache
      @custom_association_cache ||= {}
    end

    def custom_association_cached?(key)
      custom_association_cache.key?(key.to_sym)
    end

    def cache_custom_association(key, val)
      custom_association_cache[key] = val
    end

  end

end
