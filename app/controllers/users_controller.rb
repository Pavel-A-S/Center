class UsersController < ApplicationController
  before_action :set_user, only: [:show, :edit, :update, :destroy]
  before_action :must_be_administrator

  def index
    @users = User.all
  end

  def show
  end

  def new
    @user = User.new
  end

  def edit
  end

  def create
    @user = User.new(user_params)
    if @user.save
      flash[:notice] = t(:user_was_created)
      redirect_to @user
    else
      render :new
    end
  end

  def update
    if @user.update(user_params)
      flash[:notice] = t(:user_was_updated)
      redirect_to @user
    else
      render :edit
    end
  end

  def destroy
    if @user.destroy
      flash[:notice] = t(:user_was_deleted)
      redirect_to users_path
    else
      flash[:notice] = t(:user_was_not_deleted)
      redirect_to root_path
    end
  end

  private
    def set_user
      @user = User.find(params[:id])
    end

    def user_params
      params.require(:user).permit(:email, :name, :role, :password,
                                                         :password_confirmation)
    end

    def must_be_administrator
      if !current_user.administrator?
        flash.now[:alert] = t(:not_allowed)
        render template: 'errors/403'
      end
    end
end
