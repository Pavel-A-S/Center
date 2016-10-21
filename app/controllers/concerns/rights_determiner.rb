module RightsDeterminer
  extend ActiveSupport::Concern

  included do
  end

  module ClassMethods
  end

  def must_be_administrator
    if !current_user.administrator?
      flash.now[:alert] = t(:not_allowed)
      render template: 'errors/403'
    end
  end
end
