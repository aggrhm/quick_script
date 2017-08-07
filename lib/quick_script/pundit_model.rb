module QuickScript

  module PunditModel

    attr_accessor :policy

    def policy_for(user)
      @policy = Pundit.policy(user, self)
    end

  end

end
