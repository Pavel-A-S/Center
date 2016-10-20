class PortsController < ApplicationController
  before_action :set_port, only: [:show, :edit, :update, :destroy]

  def index
    @ports = Port.all
  end

  def show
  end

  def new
    @port = Port.new
  end

  def edit
  end

  def create
    @port = Port.new(port_params)
    if @port.save
      flash[:message] = t(:port_was_created)
      redirect_to @port
    else
      flash.now[:alert] = t(:port_was_not_created)
      render :new
    end
  end

  def update
    if @port.update(port_params)
      flash[:message] = t(:port_was_updated)
      redirect_to @port
    else
      flash.now[:alert] = t(:port_was_not_updated)
      render :edit
    end
  end

  def destroy
    if @port.destroy
      flash[:message] = t(:port_was_deleted)
      redirect_to ports_url
    else
      flash[:alert] = t(:port_was_not_deleted)
      redirect_to ports_path
    end
  end

  private
    def set_port
      @port = Port.find(params[:id])
    end

    def port_params
      params.require(:port).permit(:name, :order_index, :port_number,
                                                        :port_type,
                                                        :location_id,
                                                        :connection_id,
                                                        :icon,
                                                        :description)
    end
end
