module Admin
  class AirportPolicy < ApplicationPolicy
    def index?
      admin?
    end

    def update?
      admin?
    end

    def destroy?
      admin?
    end
  end
end
