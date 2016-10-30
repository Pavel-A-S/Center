class UserRecordsController < ApplicationController
  before_action :set_user_record, only: [:show, :edit, :update, :destroy]
  before_action :must_be_security_or_administrator, except: [:destroy, :update,
                                                                       :edit]
  before_action :must_be_administrator, only: [:destroy, :update, :edit]

  def index
    @user_records = UserRecord.order(created_at: :desc)
  end

  def show
  end

  def new
    @user_record = UserRecord.new
  end

  def edit
  end

  def create
    data = user_record_params
    data[:user_id] = current_user.id
    @user_record = UserRecord.new(data)
    if @user_record.save
      flash[:message] = t(:user_record_was_created)
      redirect_to @user_record
    else
      flash.now[:alert] = t(:user_record_was_not_created)
      render :new
    end
  end

  def update
    data = user_record_params
    data[:user_id] = current_user.id
    if @user_record.update(data)
      flash[:message] = t(:user_record_was_updated)
      redirect_to @user_record
    else
      flash.now[:alert] = t(:user_record_was_not_updated)
      render :edit
    end
  end

  def destroy
    if @user_record.destroy
      flash[:message] = t(:user_record_was_deleted)
      redirect_to user_records_url
    else
      flash[:alert] = t(:user_record_was_not_deleted)
      redirect_to user_records_path
    end
  end

  private
    def set_user_record
      @user_record = UserRecord.find(params[:id])
    end

    def user_record_params
      params.require(:user_record).permit(:date, :first_name,
                                                 :middle_name,
                                                 :last_name,
                                                 :initiator,
                                                 :document_type,
                                                 :document_number,
                                                 :date_of_issue,
                                                 :document_description,
                                                 :description)
    end
end
