class CarRecordsController < ApplicationController
  before_action :set_car_record, only: [:show, :edit, :update, :destroy]
  before_action :must_be_security_or_administrator

  def index
    @car_records = CarRecord.all
  end

  def show
  end

  def new
    @car_record = CarRecord.new
  end

  def edit
  end

  def create
    data = car_record_params
    data[:user_id] = current_user.id
    @car_record = CarRecord.new(data)
    if @car_record.save
      flash[:message] = t(:car_record_was_created)
      redirect_to @car_record
    else
      flash.now[:alert] = t(:car_record_was_not_created)
      render :new
    end
  end

  def update
    data = car_record_params
    data[:user_id] = current_user.id
    if @car_record.update(data)
      flash[:message] = t(:car_record_was_updated)
      redirect_to @car_record
    else
      flash.now[:alert] = t(:car_record_was_not_updated)
      render :edit
    end
  end

  def destroy
    if @car_record.destroy
      flash[:message] = t(:car_record_was_deleted)
      redirect_to car_records_url
    else
      flash[:alert] = t(:car_record_was_not_deleted)
      redirect_to car_records_path
    end
  end

  private
    def set_car_record
      @car_record = CarRecord.find(params[:id])
    end

    def car_record_params
      params.require(:car_record).permit(:date, :first_name,
                                                :middle_name,
                                                :last_name,
                                                :initiator,
                                                :document_type,
                                                :document_number,
                                                :date_of_issue,
                                                :car_number,
                                                :car_model,
                                                :cargo,
                                                :document_description,
                                                :description)
    end
end
