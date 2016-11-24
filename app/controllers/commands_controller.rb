class CommandsController < ApplicationController

  def siren
    @request = params[:command]
    if @request == 'GetState'

      # Select locations according to rights
      if current_user.administrator?
        @locations = Location.all
        @ports = Port.where(location_id: @locations) if !@locations.blank?
      elsif current_user.engineer? || current_user.security?
        @access_value = User.roles[current_user.role]
        @locations = Location.where(access: @access_value)
        if !@locations.blank?
          @ports = Port.where(location_id: @locations, access: @access_value)
        end
      end

      if !@ports.blank?

        @alert = false
        @ports_parameters = @ports.group_by { |p| p['connection_id'] }

        @ports_parameters.each do |p|
          @last_record = Record.where(connection_id: p[0]).try(:last)
          if !@last_record.blank?
            @range = Time.now - @last_record.created_at

            p[1].each do |port|

              if port.before_alert != 0 && @range >= port.before_alert
                @alert = true
              end

              if port_group(port.port_type) == 'input'
                state = 'state_' + Port.port_numbers[port.port_number].to_s
                @alert = true if @last_record[state] == 1
              end
            end
          else
            @alert = true
          end
        end
        render json: { state: @alert }
      else
        render json: { state: 'nothing' }
      end
    else
      render json: { state: 'nothing' }
    end
  end

  def command_handler
    @request = params[:command]
    if @request == 'GetData'
      @data = JSON.parse(params[:ports_parameters])
      @button_id = params[:button_id].to_s[%r{\Abutton_(.*)\z}, 1]
      if @button_id && @port = Port.find_by(id: @button_id)

        # Check user rights
        if @port.access == current_user.role || current_user.administrator?

          # Determine command
          @command = get_command(@port)

          if @connection = Connection.find_by(id: @port.connection_id)

            # Get answer from controller
            @answer = send_command(@command, @connection.login,
                                             @connection.password)

            # Set data to database
            set_data(@answer, @port.connection_id,
                              @port.connection.try(:identifier))
          end
        end
      else
        @button_id = 'no_buttons'
      end

      # Select all ports
      @ports = Port.where(id: @data)

      # Remove port if current user doesn't have right on it
      if !current_user.administrator?
        @accepted_ports = @ports.reject { |p| p.access != current_user.role }
      else
        @accepted_ports = @ports
      end

      @ports_parameters = @accepted_ports.group_by { |p| p['connection_id'] }
      @response = { button_id: @button_id,
                    ports_parameters: [] }

      location = params[:location]
      ports_with_ranges = params[:ports_with_ranges]

      @ports_parameters.each do |p|
        data = get_data(p[0], p[1], location, ports_with_ranges)
        @response[:ports_parameters].push(*data)
      end

    else
      @response = { answer: 'nothing' }
    end
    render json: @response
  end

  private

    def get_command(port)
      port_number = port.port_number.to_s

      if port.switch?
        real_port_number = port_number[%r{\Aoutput_(.*)\z}, 1]

        # Check last port state
        connection_id = port.connection_id
        data = Record.where(connection_id: connection_id).last.try(port_number)
        if data == 0
          state = 1
        else
          state = 0
        end

        # Return command
        '{"Command":"SetOutputState","Number":' + real_port_number.to_s +
                                   ',"State":' + state.to_s + '}'
      elsif port.arming_switch?

        # Set variables
        new_data = ["","","",""]
        partition_number = port_number[%r{\Apartition_(.*)\z}, 1].to_i - 1

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
                                'leak_sensor', 'smoke_sensor'].include?(type)
        'input'
      elsif ['switch', 'arming_switch'].include?(type)
        'output'
      elsif ['temperature_chart'].include?(type)
        'chart'
      elsif ['connection_checker'].include?(type)
        'checker'
      elsif ['controller_log'].include?(type)
        'log'
      else
        'undefined'
      end
    end

    def get_color(data, p)

      color = "info"

      if data
        range = Time.now - data.created_at

        if p.before_warning != 0 && range >= p.before_warning
          color = "warning"
        end

        if p.before_alert != 0 && range >= p.before_alert
          color = "danger"
        end
      end

      return color
    end


    def translate_message(record, port)
      if record.event_type == 'Arm'
        data = JSON.parse(record.description)
        message = t(:partition_arm_on) + data['Partition'].to_s
      elsif record.event_type == 'Disarm'
        data = JSON.parse(record.description)
        message = t(:partition_arm_off) + data['Partition'].to_s
      elsif record.event_type == 'InputActive'
        data = JSON.parse(record.description)

        ports = Port.where(port_number: data['Number'],
                           location_id: port.location_id,
                           access: Port.accesses[port.access])
        accepted_ports = ports.select { |p| port_group(p.port_type) == 'input' }

        names = accepted_ports.map { |p| p.name }

        message = t(:input_alert) + names.join("; ") + '.'
      elsif record.event_type == 'InputPassive'
        data = JSON.parse(record.description)

        ports = Port.where(port_number: data['Number'],
                           location_id: port.location_id,
                           access: Port.accesses[port.access])
        accepted_ports = ports.select { |p| port_group(p.port_type) == 'input' }

        names = accepted_ports.map { |p| p.name }

        message = t(:input_passive) + names.join("; ") + '.'
      elsif record.event_type == 'CaseOpen'
        message = t(:open_case)
      elsif record.event_type == 'DeviceOn'
        message = t(:device_on)
      elsif record.event_type == 'Test'
        message = t(:test_message_from_device)
      else
        record.description
      end
    end

    def get_data(connection_id, ports, location, ports_with_ranges)

      # Select last record only one time
      if !(ports.all? { |x| port_group(x.port_type) == 'chart' ||
                            port_group(x.port_type) == 'checker' ||
                            port_group(x.port_type) == 'log' })
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

          # Set color depending on port settings
          color = get_color(data, p)

        elsif port_group(p.port_type) == 'output'
          state = p.port_number

          # Set color depending on port settings
          color = get_color(data, p)

        elsif port_group(p.port_type) == 'chart'
          if location == 'page'

            if !ports_with_ranges.blank?
              if port = ports_with_ranges.find { |pwr| pwr[0] == p.id }
                range = port[2].to_i.days
              else
                range = 1.day
              end
            else
              range = 1.day
            end

            voltage = 'voltage_' + Port.port_numbers[p.port_number].to_s
            raw_data = Record.where(connection_id: p.connection_id)
                             .where('created_at > ?', DateTime.now - range)
                             .pluck(voltage, 'created_at') rescue nil

            chart_data = convert_chart_data(raw_data) if !raw_data.blank?
          else
            chart_data = 'no data'
          end
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
            local_time = (created_at + Time.now.utc_offset)
                         .strftime("%H:%M:%S %d.%m.%Y")
          else
            state = 1
            local_time = "No data"
            created_at = "No data"
          end
        elsif port_group(p.port_type) == 'log'
          if location == 'page'

            if !ports_with_ranges.blank?
              if port = ports_with_ranges.find { |pwr| pwr[0] == p.id }
                range = port[2].to_i
              else
                range = 5
              end
            else
              range = 5
            end

            log = Log.where(connection_id: p.connection_id)
                     .order(created_at: :desc).limit(range)

            records = [{ created_at: CGI::escapeHTML(t(:created_at)),
                         event_id: CGI::escapeHTML(t(:event_id)),
                         event_type: CGI::escapeHTML(t(:event_type)),
                         description: CGI::escapeHTML(t(:description)) }]
            log.each do |r|
              time = r.created_at + Time.now.utc_offset
              description = translate_message(r, p)
              records << { created_at: time.strftime("%H:%M:%S %d.%m.%y"),
                           event_id: CGI::escapeHTML(r.event_id.to_s),
                           event_type: CGI::escapeHTML(r.event_type),
                           description: CGI::escapeHTML(description) }
            end
          else
            records = 'no data'
          end
        end

        # Prepare answer depending on port type
        if (data && !(port_group(p.port_type) == 'chart' ||
                      port_group(p.port_type) == 'checker' ||
                      port_group(p.port_type) == 'log')) ||
           (chart_data && port_group(p.port_type) == 'chart') ||
           (created_at && port_group(p.port_type) == 'checker') ||
           (records && port_group(p.port_type) == 'log')

          case p.port_type
          when 'temperature_sensor'
            temperature = (((data[voltage].to_f*10/4095)/5 - 0.5)/0.01).round(2)
            output << { state: data[state],
                        color: color,
                        temperature: temperature,
                        location_id: p.location_id,
                        port_type: p.port_type,
                        port_id: p.id }

          when 'reed_switch'
            if data[state] == 0
              text = t(:closed)
            else
              text = t(:opened)
            end
            output << { state: data[state],
                        color: color,
                        location_id: p.location_id,
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
                        color: color,
                        location_id: p.location_id,
                        text: text,
                        port_type: p.port_type,
                        port_id: p.id }
          when 'smoke_sensor'
            if data[state] == 0
              text = t(:no_smoke)
            else
              text = t(:smoke_is_detected)
            end
            output << { state: data[state],
                        color: color,
                        location_id: p.location_id,
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
                        color: color,
                        location_id: p.location_id,
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
                        color: color,
                        location_id: p.location_id,
                        text: text,
                        button_text: button_text,
                        port_type: p.port_type,
                        port_id: p.id }
          when 'arming_switch'
            if data[state] == "Arm"
              alias_state = 1
              text = t(:armed)
              button_text = t(:arm_off)
            elsif data[state] == "Disarm"
              alias_state = 0
              text = t(:disarmed)
              button_text = t(:arm_on)
            end
            output << { state: alias_state,
                        color: color,
                        location_id: p.location_id,
                        text: text,
                        button_text: button_text,
                        port_type: p.port_type,
                        port_id: p.id }
          when 'temperature_chart'
            output << { state: 0,
                        chart_data: chart_data,
                        title: p.name,
                        text: t(:select_days),
                        location_id: p.location_id,
                        port_type: p.port_type,
                        port_id: p.id }
          when 'connection_checker'
            output << { state: state,
                        location_id: p.location_id,
                        created_at: local_time,
                        port_type: p.port_type,
                        port_id: p.id }
          when 'controller_log'
            output << { state: 0,
                        location_id: p.location_id,
                        records: records,
                        title: p.name,
                        text: t(:records_count),
                        port_type: p.port_type,
                        port_id: p.id }
          end
        end
      end
      output
    end
end
