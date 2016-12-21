module QuickScript

  class HashModel

    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods

      def field(name, opts)
        fields[name] = opts.merge(name: name)

        define_method name do
          fopts = fields[name]
          ft = fopts[:type]
          val = self.parent_source[name.to_s]
          case ft
          when Time
            rv = Time.at(val)
          else
            rv = ret
          end
          return rv
        end

        define_method "#{name}=" do |val|
          fopts = fields[name]
          ft = fopts[:type]

          case ft
          when Integer
            sv = val.to_i
          when Float
            sv = val.to_f
          when Time
            sv = val.to_i
          else
            sv = val
          end
          self.parent_source[name.to_s] = sv
        end
      end

      def fields
        @fields ||= {}
      end

      def from_parent(parent, hash)
        m = self.new
        m.set_parent(parent, hash)
        return m
      end

    end

    def id
      ret = parent_source['id']
      if ret.blank?
        ret = parent_source['id'] = SecureRandom.uuid.gsub("-", "")
      end
      return ret
    end

    def set_parent(parent, hash)
      @parent_model = parent
      @parent_source = hash
    end

    def parent_model
      @parent_model
    end

    def parent_source
      @parent_source ||= {}
    end

    def new_record?
      return true if parent_model.nil?
      return parent_model.new_record?
    end

    def valid?
      true
    end

  end

end
