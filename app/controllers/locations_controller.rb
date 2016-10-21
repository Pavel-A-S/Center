class LocationsController < ApplicationController
  before_action :set_location, only: [:show, :edit, :update, :destroy, :page]
  before_action :must_be_administrator, except: [:user_index, :page]

  def index
    @locations = Location.all
  end

  def user_index

    # Select locations according to rights
    if current_user.administrator?
      @locations = Location.all
    elsif current_user.engineer? || current_user.security?
      @access_value = User.roles[current_user.role]
      @locations = Location.where(access: @access_value)
    else
      @locations = nil
    end

    if @locations
      @excepted_port = Port.port_types['temperature_chart']
      @ports_ids = Port.where(connection_id: @locations)
                       .where.not(port_type: @excepted_port)
                       .pluck(:id)
    end
  end

  def show
  end

  def page
    if @location

      # Select locations according to rights
      if current_user.administrator?
        @ports = @location.ports.order(:order_index)
      elsif current_user.engineer? || current_user.security?
        @access_value = User.roles[current_user.role]
        @ports = @location.ports.where(access: @access_value)
                                .order(:order_index)
      end
      @ports_ids = @ports.map { |p| p.id }
    end
  end

  def new
    @location = Location.new
  end

  def edit
  end

  def create
    @location = Location.new(location_params)
    if @location.save
      flash[:message] = t(:location_was_created)
      redirect_to @location
    else
      flash.now[:alert] = t(:location_was_not_created)
      render :new
    end
  end

  def update
    if @location.update(location_params)
      flash[:message] = t(:location_was_updated)
      redirect_to @location
    else
      flash.now[:alert] = t(:location_was_not_updated)
      render :edit
    end
  end

  def destroy
    if @location.destroy
      flash[:message] = t(:location_was_deleted)
      redirect_to locations_url
    else
      flash[:alert] = t(:location_was_not_deleted)
      redirect_to locations_path
    end
  end

  private
    def set_location
      @location = Location.find(params[:id])
    end

    def location_params
      params.require(:location).permit(:name, :description, :access)
    end
end
