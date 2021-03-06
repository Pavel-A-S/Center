# Users controller
class UsersController < ApplicationController
  before_action :set_user, only: %i[show edit update destroy]
  before_action :must_be_administrator

  def index
    @users = User.all
  end

  def show; end

  def new
    @user = User.new
  end

  def edit; end

  def create
    @user = User.new(user_params)
    if @user.save
      flash[:message] = t(:user_was_created)
      redirect_to @user
    else
      flash.now[:alert] = t(:user_was_not_created)
      render :new
    end
  end

  def update
    values = if params[:user].is_a?(Hash) &&
                params[:user][:password_confirmation].empty? &&
                params[:user][:password].empty?
               user_params_short
             else
               user_params
             end

    if @user.update(values)
      flash[:message] = t(:user_was_updated)
      redirect_to @user
    else
      flash.now[:alert] = t(:user_was_not_updated)
      render :edit
    end
  end

  def destroy
    if @user.destroy
      flash[:message] = t(:user_was_deleted)
      redirect_to users_path
      return
    end
    flash[:alert] = t(:user_was_not_deleted)
    redirect_to users_path
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(
      :email, :name, :role, :password, :password_confirmation
    )
  end

  def user_params_short
    params.require(:user).permit(:email, :name, :role)
  end
end
