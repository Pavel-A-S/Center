class LocationsController < ApplicationController
  before_action :set_location, only: [:show, :edit, :update, :destroy, :page]

  def index
    @locations = Location.all
  end

  def show
  end

  def page
    @ports = @location.ports.try(:order, :order_index)
    @ports_parameters = []
    @ports.each do |p|


      data = { name: p.name,
               port_type: p.port_type,
               port_number: p.port_number,
               port_id: p.id,
               connection_id: p.connection_id }

      data[:identifier] = p.connection.try(:identifier) if p.switch?

      @ports_parameters << data
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
      params.require(:location).permit(:name, :description)
    end
end
