class EventRecordsController < ApplicationController
  before_action :set_event_record, only: [:show, :edit, :update, :destroy]
  before_action :must_be_security_or_administrator, except: [:destroy, :update,
                                                                       :edit]
  before_action :must_be_administrator, only: [:destroy, :update, :edit]

  def index
    @event_records = EventRecord.order(created_at: :desc)
  end

  def show
  end

  def new
    @event_record = EventRecord.new
  end

  def edit
  end

  def create
    data = event_record_params
    data[:user_id] = current_user.id
    @event_record = EventRecord.new(data)
    if @event_record.save
      flash[:message] = t(:event_record_was_created)
      redirect_to @event_record
    else
      flash.now[:alert] = t(:event_record_was_not_created)
      render :new
    end
  end

  def update
    data = event_record_params
    data[:user_id] = current_user.id
    if @event_record.update(data)
      flash[:message] = t(:event_record_was_updated)
      redirect_to @event_record
    else
      flash.now[:alert] = t(:event_record_was_not_updated)
      render :edit
    end
  end

  def destroy
    if @event_record.destroy
      flash[:message] = t(:event_record_was_deleted)
      redirect_to event_records_url
    else
      flash[:alert] = t(:event_record_was_not_deleted)
      redirect_to event_records_path
    end
  end

  private
    def set_event_record
      @event_record = EventRecord.find(params[:id])
    end

    def event_record_params
      params.require(:event_record).permit(:description, :date)
    end
end
