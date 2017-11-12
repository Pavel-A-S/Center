# Application controller
class ApplicationController < ActionController::Base
  include RightsDeterminer
  before_action :authenticate_user!
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  def after_sign_in_path_for(_user)
    user_index_locations_path
  end
end
