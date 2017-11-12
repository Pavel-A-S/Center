# Rights determiner
module RightsDeterminer
  extend ActiveSupport::Concern

  included do
  end

  # Class methods
  module ClassMethods
  end

  def must_be_administrator
    return if current_user.administrator?
    flash.now[:alert] = t(:not_allowed)
    render template: 'errors/403'
  end

  def must_be_security_or_administrator
    return if current_user.security? || current_user.administrator?
    flash.now[:alert] = t(:not_allowed)
    render template: 'errors/403'
  end
end
