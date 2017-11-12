# Locations controller
class LocationsController < ApplicationController
  before_action :set_location, only: %i[show edit update destroy page]
  before_action :must_be_administrator, except: %i[user_index page]

  def index
    @locations = Location.order(created_at: :desc)
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

    @ports_ids = Port.where(location_id: @locations).pluck(:id) if @locations
  end

  def show; end

  def page
    return unless @location

    # Select locations according to rights
    if current_user.administrator?
      @ports = @location.ports.order(:order_index)
    elsif current_user.engineer? || current_user.security?
      @access_value = User.roles[current_user.role]
      @ports = @location.ports
                        .where(access: @access_value)
                        .order(:order_index)
    end

    @ports_ids = @ports.map(&:id)
    @accepted_ports = [Port.port_types['temperature_chart'],
                       Port.port_types['voltage_chart'],
                       Port.port_types['controller_log']]
    @ports_with_ranges = @ports.where(port_type: @accepted_ports)
                               .pluck(:id, :port_type)
  end

  def new
    @location = Location.new
  end

  def edit; end

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
