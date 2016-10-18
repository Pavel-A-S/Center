class CommandsController < ApplicationController

  def command_handler
    @request = params[:command]
    if @request == 'GetData'
      @data = JSON.parse(params[:ports_parameters])
      if params[:selected_buttons]
        @selected_buttons = JSON.parse(params[:selected_buttons])
        @selected_buttons.each do |b|
          port_parameters = @data.find { |x| x['port_id'] == b }

          # Determine command
          @command = get_command(port_parameters)

          # Get answer from controller
          @id = port_parameters['connection_id']
          if @connection = Connection.find_by(id: @id)

            @answer = send_command(@command, @connection['login'],
                                             @connection['password'])

            # Set data to database
            set_data(@answer, port_parameters['connection_id'],
                              port_parameters['identifier'])
          end
        end
      end

      @selected_buttons ||= 'no_buttons'

      @ports_ids = @data.map { |p| p['port_id'] }
      @ports = Port.where(id: @ports_ids)

      @ports_parameters = @ports.group_by { |p| p['connection_id'] }
      @response = { ports_parameters: [], selected_buttons: @selected_buttons }

      @ports_parameters.each do |p|
        @response[:ports_parameters].push(*get_data(p[0], p[1]))
      end

    else
      @response = { answer: 'nothing' }
    end

    render json: @response
  end

  private

    def get_command(input)
      port_number = input['port_number']

      if real_port_number = input['port_number'][%r{\Aoutput_(.*)\z}, 1]

        connection_id = input['connection_id']
        data = Record.where(connection_id: connection_id).last.try(port_number)
        if data == 0
          command = '{"Command":"SetOutputState","Number":' + real_port_number +
                                               ',"State":1}'
        else
          command = '{"Command":"SetOutputState","Number":' + real_port_number +
                                               ',"State":0}'
        end
        return command
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
      return res
    end

    def set_data(message, connection_id, identifier)
      data = JSON.parse message.body rescue "nope"

      # Check for errors
      if data != 'nope' && data.is_a?(Hash) &&
        (["Inputs","Outputs"].all? { |key| data.has_key? key }) &&
        data["Inputs"].is_a?(Array) && data["Outputs"].is_a?(Array) &&
        data["Inputs"].length == 16 && data["Outputs"].length == 7

        @record = Record.new
        @record.connection_id = connection_id
        @record.controller_identifier = identifier
        @record.voltage_1 = data["Inputs"][0]["Voltage"]
        @record.voltage_2 = data["Inputs"][1]["Voltage"]
        @record.voltage_3 = data["Inputs"][2]["Voltage"]
        @record.voltage_4 = data["Inputs"][3]["Voltage"]
        @record.voltage_5 = data["Inputs"][4]["Voltage"]
        @record.voltage_6 = data["Inputs"][5]["Voltage"]
        @record.voltage_7 = data["Inputs"][6]["Voltage"]
        @record.voltage_8 = data["Inputs"][7]["Voltage"]
        @record.voltage_9 = data["Inputs"][8]["Voltage"]
        @record.voltage_10 = data["Inputs"][9]["Voltage"]
        @record.voltage_11 = data["Inputs"][10]["Voltage"]
        @record.voltage_12 = data["Inputs"][11]["Voltage"]
        @record.voltage_13 = data["Inputs"][12]["Voltage"]
        @record.voltage_14 = data["Inputs"][13]["Voltage"]
        @record.voltage_15 = data["Inputs"][14]["Voltage"]
        @record.voltage_16 = data["Inputs"][15]["Voltage"]
        @record.state_1 = data["Inputs"][0]["Active"]
        @record.state_2 = data["Inputs"][1]["Active"]
        @record.state_3 = data["Inputs"][2]["Active"]
        @record.state_4 = data["Inputs"][3]["Active"]
        @record.state_5 = data["Inputs"][4]["Active"]
        @record.state_6 = data["Inputs"][5]["Active"]
        @record.state_7 = data["Inputs"][6]["Active"]
        @record.state_8 = data["Inputs"][7]["Active"]
        @record.state_9 = data["Inputs"][8]["Active"]
        @record.state_10 = data["Inputs"][9]["Active"]
        @record.state_11 = data["Inputs"][10]["Active"]
        @record.state_12 = data["Inputs"][11]["Active"]
        @record.state_13 = data["Inputs"][12]["Active"]
        @record.state_14 = data["Inputs"][13]["Active"]
        @record.state_15 = data["Inputs"][14]["Active"]
        @record.state_16 = data["Inputs"][15]["Active"]
        @record.output_1 = data["Outputs"][0]
        @record.output_2 = data["Outputs"][1]
        @record.output_3 = data["Outputs"][2]
        @record.output_4 = data["Outputs"][3]
        @record.output_5 = data["Outputs"][4]
        @record.output_6 = data["Outputs"][5]
        @record.output_7 = data["Outputs"][6]
        @record.profile = data["Case"]
        @record.temp = data["Temp"]
        @record.power = data["Power"]
        @record.partition_1 = data["Partitions"][0]
        @record.partition_2 = data["Partitions"][1]
        @record.partition_3 = data["Partitions"][2]
        @record.partition_4 = data["Partitions"][3]
        @record.battery_state = data["Battery"]["State"]
        @record.balance = data["Balance"]
        @record.full_message = data
        @record.save
        return @record
      else
        return data
      end
    end

    def convert_chart_data(data)
      data.each do |d|
        temperature = (((d[0].to_f*10/4095)/5 - 0.5)/0.01).round(2)
        d[0] = temperature
      end
    end

    def port_group(type)
      if ['temperature_sensor', 'reed_switch', 'motion_sensor',
                                               'leak_sensor'].include?(type)
        'input'
      elsif ['switch'].include?(type)
        'output'
      elsif ['temperature_chart'].include?(type)
        'chart'
      elsif ['connection_checker'].include?(type)
        'checker'
      else
        'undefined'
      end
    end

    def get_data(connection_id, ports)

      # Select last record only one time
      if !(ports.all? { |x| port_group(x.port_type) == 'chart' ||
                            port_group(x.port_type) == 'checker'})
        data = Record.where(connection_id: connection_id).try(:last)
      end
      output = []

      ports.each do |p|

        # Initialize variables
        raw_data = nil
        created_at = nil

        # Set values depending on port type
        if port_group(p.port_type) == 'input'
          voltage = 'voltage_' + Port.port_numbers[p.port_number].to_s
          state = 'state_' + Port.port_numbers[p.port_number].to_s
        elsif port_group(p.port_type) == 'output'
          state = p.port_number
        elsif port_group(p.port_type) == 'chart'
          voltage = 'voltage_' + Port.port_numbers[p.port_number].to_s
          raw_data = Record.where(connection_id: p.connection_id)
                           .pluck(voltage, 'created_at')
                           .try(:last, 1000) rescue nil
          chart_data = convert_chart_data(raw_data) if !raw_data.blank?
        elsif port_group(p.port_type) == 'checker'
          time_out = p.connection.try(:time_out)
          created_at = Record.where(connection_id: p.connection_id)
                             .last
                             .try(:created_at)
          if time_out && created_at
            if created_at + time_out.seconds < DateTime.now
              state = 1
            else
              state = 0
            end
          else
            state = 1
          end
        end

        # Prepare answer depending on port type
        if (data && !(port_group(p.port_type) == 'chart' ||
                      port_group(p.port_type) == 'checker')) ||
           (chart_data && port_group(p.port_type) == 'chart') ||
           (created_at && port_group(p.port_type) == 'checker')

          case p.port_type
          when 'temperature_sensor'
            temperature = (((data[voltage].to_f*10/4095)/5 - 0.5)/0.01).round(2)
            output << { temperature: temperature,
                        state: data[state],
                        port_type: p.port_type,
                        port_id: p.id }

          when 'reed_switch'
            if data[state] == 0
              text = t(:closed)
            else
              text = t(:opened)
            end
            output << { state: data[state],
                        text: text,
                        port_type: p.port_type,
                        port_id: p.id }
          when 'motion_sensor'
            if data[state] == 0
              text = t(:no_motion)
            else
              text = t(:motion_is_detected)
            end
            output << { state: data[state],
                        text: text,
                        port_type: p.port_type,
                        port_id: p.id }
          when 'leak_sensor'
            if data[state] == 0
              text = t(:no_leak)
            else
              text = t(:leak_is_detected)
            end
            output << { state: data[state],
                        text: text,
                        port_type: p.port_type,
                        port_id: p.id }
          when 'switch'
            if data[state] == 0
              text = t(:stopped)
              button_text = t(:switch_on)
            else
              text = t(:started)
              button_text = t(:switch_off)
            end
            output << { state: data[state],
                        text: text,
                        button_text: button_text,
                        port_type: p.port_type,
                        port_id: p.id }
          when 'temperature_chart'
            output << { chart_data: chart_data,
                        port_type: p.port_type,
                        port_id: p.id }
          when 'connection_checker'
            local_time = (created_at + Time.now.utc_offset)
                         .strftime("%H:%M:%S %d.%m.%Y")
            output << { state: state,
                        created_at: local_time,
                        port_type: p.port_type,
                        port_id: p.id }
          end
        end
      end
      output
    end
end
