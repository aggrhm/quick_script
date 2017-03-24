module QuickScript

  module Stateable

    def self.included(base)
      base.send :extend, ClassMethods
    end

    module ClassMethods

      def states
        @states ||= {}
      end

      def state(enum, val)
        states[enum] = val
      end

      def stateable!(opts={})
        orm = stateable_orm
        if orm == :mongoid
          stateable_mongoid!
        elsif orm == :active_record
          stateable_active_record!
        end
      end

      def stateable_orm
        if self < ActiveRecord::Base
          return :active_record
        elsif self.respond_to?(:mongo_session)
          return :mongoid
        end
      end

      def stateable_mongoid!
        include MongoHelper::Model

        field :st, as: :state, type: Integer, default: 1
        field :st_at, as: :state_changed_at, type: Time

        enum_methods! :state, states

        scope :with_state, lambda {|st|
          # convert to int
          ar = st.is_a?(Array) ? st : [st]
          ar = ar.collect {|v|
            if v.is_a?(String)
              if states.keys?(v.to_sym)
                states[v.to_sym]
              else
                v.to_i
              end
            elsif v.is_a?(Symbol)
              states[v]
            else
              v
            end
          }
          where('st' => {'$in' => ar})
        }
        scope :has_state, lambda {|st|
          with_state(st)
        }
        scope :active, lambda {
          where("st" => {'$in' => [nil, states[:active]]})
        }
        scope :archived, lambda {
          where(st: states[:archived])
        }
        scope :not_deleted, lambda {
          where(:st.ne => states[:deleted])
        }
      end

      def stateable_active_record!
        include QuickScript::Model

        if self.respond_to?(:field)
          field :state, type: Integer, default: 1
          field :state_changed_at, type: Time
        end

        enum_methods! :state, states

        scope :with_state, lambda {|st|
          # convert to int
          ar = st.is_a?(Array) ? st : [st]
          ar = ar.collect {|v|
            if v.is_a?(String)
              states.keys?(v.to_sym) ? states[v.to_sym] : v.to_i
            elsif v.is_a?(Symbol)
              states[v]
            else
              v
            end
          }
          where(state: ar)
        }
        scope :has_state, lambda {|st|
          with_state(st)
        }
        scope :active, lambda {
          where(state: [nil, states[:active]])
        }
        scope :not_deleted, lambda {
          where("state <> ?", states[:deleted])
        }
      end

    end

    def set_state!(state)
      self.state! state
      self.save(validate: false)
    end

  end

end
