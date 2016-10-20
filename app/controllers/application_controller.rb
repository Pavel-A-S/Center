class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  def after_sign_in_path_for(user)
    if user.security?
      users_index_path
    elsif user.engineer?
      users_index_path
    else
      users_index_path
    end
  end
end
