module QuickScript

  module PunditModel

    attr_accessor :policy

    def policy_for(user)
      @policy = Pundit.policy(user, self)
    end

  end

  class PunditPolicy
    attr_reader :user, :record

    def authorize!(query, opts={})
      opts[:message] ||= "You don't have permission to perform this action or view this resource."
      if !self.send(query)
        raise Pundit::NotAuthorizedError, query: query, record: record, policy: self, message: opts[:message]
      end
      return record
    end

    def initialize(user, record)
      @user = user
      @record = record
    end

    def index?
      false
    end

    def view?
      scope.where(:id => record.id).exists?
    end

    def show?
      view?
    end

    def create?
      false
    end

    def new?
      create?
    end

    def update?
      false
    end

    def edit?
      update?
    end

    def delete?
      update?
    end

    def destroy?
      delete?
    end

    def scope
      Pundit.policy_scope!(user, record.class)
    end

  end

  class PunditScope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      scope
    end
  end

end
