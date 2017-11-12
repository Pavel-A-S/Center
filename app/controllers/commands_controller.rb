# Commands Controller
class CommandsController < ApplicationController
  include PortsStates
  include DataSetter

  def siren
    @request = params[:command]
    return render json: { state: 'nothing' } unless @request == 'GetState'

    # Select locations according to the rights
    if current_user.administrator?
      @locations = Location.all
      @ports = Port.where(location_id: @locations) unless @locations.blank?
    elsif current_user.engineer? || current_user.security?
      @locations = Location.where(access: user_role)
      unless @locations.blank?
        @ports = Port.where(location_id: @locations, access: user_role)
      end
    end

    if @ports.blank?
      render json: { state: 'nothing' }
      return
    end

    @ports.group_by { |p| p['connection_id'] }.each do |p|
      @last_record = Record.where(connection_id: p[0]).try(:last)
      @alert = alert_detected?(p[1], @last_record)
    end
    render json: { state: @alert || false }
  end

  def command_handler
    @request = params[:command]
    unless @request == 'GetData'
      @response = { answer: 'nothing' }
      render(json: @response) && return
    end
    @data = JSON.parse(params[:ports_parameters])
    @button_id = params[:button_id].to_s[/\Abutton_(.*)\z/, 1]

    @port = Port.find_by(id: @button_id) if @button_id

    # Check user rights
    if @port &&
       @port.enabled? &&
       (@port.access == current_user.role || current_user.administrator?)

      # Determine command
      @command = get_command(@port)

      @connection = Connection.find_by(id: @port.connection_id)
      if @connection
        answer = send_command(@command, @connection.login, @connection.password)
        set_data(answer, @port.connection_id, @port.connection.try(:identifier))
      end

    else
      @button_id = 'no_buttons'
    end

    # Select all ports
    @ports = Port.where(id: @data)

    # Select port if current user has rights on it
    @accepted_ports = if !current_user.administrator?
                        @ports.select { |p| p.access == current_user.role }
                      else
                        @ports
                      end

    @ports_parameters = @accepted_ports.group_by { |p| p['connection_id'] }
    @response = { button_id: @button_id, ports_parameters: [] }

    @ports_parameters.each do |p|
      data = get_data(p[0], p[1], params[:location], params[:ports_with_ranges])
      @response[:ports_parameters].push(*data)
    end

    render json: @response
  end

  private

  def alert_detected?(port, last_record)
    return true if last_record.blank?
    range = Time.now - last_record.created_at
    port.each do |p|
      next unless p.enabled?
      return true if p.before_alert != 0 && range >= p.before_alert
      next unless port_group(p.port_type) == 'common_ports'
      state = 'state_' + Port.port_numbers[p.port_number].to_s
      return true if last_record[state] == 1
    end
    false
  end

  def user_role
    User.roles[current_user.role]
  end

  def get_command(port)
    port_number = port.port_number.to_s

    if port.switch?
      real_port_number = port_number[/\Aoutput_(.*)\z/, 1]

      # Check last port state
      connection_id = port.connection_id
      data = Record.where(connection_id: connection_id).last.try(port_number)
      state = data.zero? ? 1 : 0

      # Return command
      '{"Command":"SetOutputState","Number":' + real_port_number.to_s +
        ',"State":' + state.to_s + '}'
    elsif port.arming_switch?

      # Set variables
      new_data = ['', '', '', '']
      partition_number = port_number[/\Apartition_(.*)\z/, 1].to_i - 1

      # Check last port state
      connection_id = port.connection_id
      data = Record.where(connection_id: connection_id).last.try(port_number)
      if data == 'Disarm'
        new_data[partition_number] = 'Arm'
      elsif data == 'Arm'
        new_data[partition_number] = 'Disarm'
      end

      # Return command
      '{"Command":"SetPartitionsState","State":' + new_data.to_json + '}'
    else
      return 'nothing'
    end
  end

  def send_command(command, login, password)
    begin
      uri = URI("https://ccu.sh/data.cgx?cmd=#{command}")
      res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
        req = Net::HTTP::Get.new(uri)
        req.basic_auth login, password
        http.read_timeout = 15
        http.request(req)
      end
    rescue
      res = 'nope'
    end
    res
  end

  # Returns data for each "virtual port"
  def get_data(connection_id, ports, location, ports_with_ranges)
    # Select last record only once
    unless ports.all? { |x| port_group(x.port_type) == 'special_ports' }
      data = Record.where(connection_id: connection_id).try(:last)
    end
    output = []

    ports.each do |p|
      next if !data && port_group(p.port_type) != 'special_ports'

      # Set values depending on port type
      if port_group(p.port_type) == 'common_ports'
        output << common_port(p, data)
      elsif p.port_type == 'temperature_sensor'
        output << temperature_sensor(p, data)
      elsif p.port_type == 'controller_raw_data'
        output << controller_raw_data(p, data)
      elsif p.port_type == 'pressure_sensor'
        output << pressure_sensor(p, data)
      elsif p.port_type == 'switch'
        output << switch(p, data)
      elsif p.port_type == 'arming_switch'
        output << arming_switch(p, data)
      elsif p.port_type == 'temperature_chart'
        output << temperature_chart(p, location, ports_with_ranges)
      elsif p.voltage_chart?
        output << voltage_chart(p, location, ports_with_ranges)
      elsif p.port_type == 'connection_checker'
        output << connection_checker(p)
      elsif p.port_type == 'controller_log'
        output << controller_log(p, location, ports_with_ranges)
      end
    end
    output
  end
end
