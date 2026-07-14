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

    private

    def admin?
      user&.admin? == true
    end
  end
end
