class TravelSegmentPolicy < ApplicationPolicy
  def index?
    user&.active? || false
  end

  alias_method :create?, :index?

  def show?
    index? && record.user_id == user.id
  end

  alias_method :update?, :show?
  alias_method :destroy?, :show?

  class Scope < ApplicationPolicy::Scope
    def resolve
      user&.active? ? scope.where(user_id: user.id) : scope.none
    end
  end
end
