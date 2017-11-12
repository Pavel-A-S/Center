# Connections controller
class ConnectionsController < ApplicationController
  before_action :set_connection, only: %i[show edit update destroy]
  before_action :must_be_administrator

  def index
    @connections = Connection.all
  end

  def show; end

  def new
    @connection = Connection.new
  end

  def edit; end

  def create
    @connection = Connection.new(connection_params)
    if @connection.save
      flash[:message] = t(:connection_was_created)
      redirect_to @connection
    else
      flash.now[:alert] = t(:connection_was_not_created)
      render :new
    end
  end

  def update
    if @connection.update(connection_params)
      flash[:message] = t(:connection_was_updated)
      redirect_to @connection
    else
      flash.now[:alert] = t(:connection_was_not_updated)
      render :edit
    end
  end

  def destroy
    if @connection.destroy
      flash[:message] = t(:connection_was_deleted)
      redirect_to connections_url
    else
      flash[:alert] = t(:connection_was_not_deleted)
      redirect_to connections_path
    end
  end

  private

  def set_connection
    @connection = Connection.find(params[:id])
  end

  def connection_params
    params.require(:connection).permit(
      :name, :login, :password, :identifier, :description, :frequency,
      :time_out, :update_me
    )
  end
end
