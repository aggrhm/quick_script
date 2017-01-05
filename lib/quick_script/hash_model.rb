module QuickScript

  module HashModel

    def self.included(base)
      base.extend ClassMethods
      base.send :include, QuickScript::Model
    end

    module ClassMethods

      def field(name, opts)
        fields[name] = opts.merge(name: name)

        define_method name do
          fopts = self.class.fields[name]
          ft = fopts[:type]
          val = self.attributes[name.to_s]
          case ft
          when Time
            rv = Time.at(val)
          else
            rv = val
          end
          if rv.nil? && (df = fopts[:default])
            if df.is_a?(Proc)
              rv = self.instance_exec(&df)
            else
              rv = df
            end
            self.attributes[name.to_s] = rv
          end
          return rv
        end

        define_method "#{name}=" do |val|
          fopts = self.class.fields[name]
          ft = fopts[:type]

          case ft
          when Integer
            sv = val.to_i
          when Float
            sv = val.to_f
          when Time
            sv = val.to_i
          when :boolean
            sv = QuickScript.parse_bool(val)
          else
            sv = val
          end
          self.attributes[name.to_s] = sv
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
      ret = attributes['id']
      if ret.blank?
        ret = attributes['id'] = SecureRandom.uuid.gsub("-", "")
      end
      return ret
    end

    def set_parent(parent, hash)
      @parent_model = parent
      @attributes = hash
    end

    def parent_model
      @parent_model
    end

    def attributes
      @attributes ||= {}
    end

    def new_record?
      return true if parent_model.nil?
      return parent_model.new_record?
    end

    def persisted?
      !new_record?
    end

    def validate!

    end

    def valid?
      self.validate!
      return errors.none?
    end

    def errors
      @errors ||= ActiveModel::Errors.new(self)
    end

    def save
      return false if !valid?
      if parent_model
        if parent_model.persisted?
          parent_model.save
        else
          valid?
        end
      else
        return false
      end
    end

  end

end
