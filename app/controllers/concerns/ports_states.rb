# Ports states
module PortsStates
  extend ActiveSupport::Concern

  #=============================== Ports ======================================

  def voltage_chart(port, location, ports_with_ranges)
    if location == 'page'
      unless ports_with_ranges.blank?
        target_port = ports_with_ranges.find { |pwr| pwr[0] == port.id }
      end

      range = if !ports_with_ranges.blank? &&
                 target_port &&
                 target_port[2].to_i > 0 &&
                 target_port[2].to_i <= 14
                target_port[2].to_i.days
              else
                1.day
              end

      voltage = 'voltage_' + Port.port_numbers[port.port_number].to_s
      raw_data = Record.where(connection_id: port.connection_id)
                       .where('created_at > ?', Time.now - range)
                       .pluck(voltage, 'created_at') rescue nil

      chart_data = voltage_chart_data(raw_data) unless raw_data.blank?
    else
      chart_data = 'no data'
    end
    {
      state: 0,
      chart_data: chart_data,
      title: port.name,
      axis_y_title: t('voltage_chart.axis_y_title'),
      text: t(:select_days),
      location_id: port.location_id,
      port_type: port.port_type,
      port_id: port.id
    }
  end

  def controller_raw_data(port, data)
    ports_data = [{
      name: t('controller_raw_data.port'),
      state: t('controller_raw_data.state'),
      voltage: t('controller_raw_data.voltage')
    }]
    (1..16).each do |i|
      ports_data << {
        name: "In #{i}",
        state: data["state_#{i}"],
        voltage: (data["voltage_#{i}"].to_f * 10 / 4095).round(2).to_s
      }
    end

    {
      state: 0,
      title: port.name,
      ports_data: ports_data,
      color: get_color(data, port),
      location_id: port.location_id,
      port_type: port.port_type,
      port_id: port.id
    }
  end

  def pressure_sensor(port, data)
    port1_state = 'state_' + Port.port_numbers[port.port_number].to_s
    port2_state = 'state_' +
                  Port.extra_port_numbers[port.extra_port_number].to_s
    port_state = port.enabled? ? data[port1_state] | data[port2_state] : 7
    color = get_color(data, port)

    text = if data[port1_state].zero? && data[port2_state].zero?
             t(:norm)
           elsif data[port1_state] == 1
             t(:below_the_norm)
           elsif data[port2_state] == 1
             t(:above_the_norm)
           elsif port_state == 7
             t(:port_disabled)
           end

    {
      state: port_state,
      color: color,
      location_id: port.location_id,
      text: text,
      port_type: port.port_type,
      port_id: port.id
    }
  end

  def connection_checker(port)
    time_out = port.connection.try(:time_out)
    created_at = Record.where(connection_id: port.connection_id)
                       .last
                       .try(:created_at)
    if time_out && created_at
      state = created_at + time_out.seconds < Time.now ? 1 : 0
      local_time = (created_at + Time.now.utc_offset)
                   .strftime('%H:%M:%S %d.%m.%Y')
    else
      state = 1
      local_time = 'No data'
    end

    {
      state: state,
      location_id: port.location_id,
      created_at: local_time,
      port_type: port.port_type,
      port_id: port.id
    }
  end

  # Reed switch, Motion sensor, Leak sensor, Smoke sensor
  def common_port(port, data)
    state = data['state_' + Port.port_numbers[port.port_number].to_s]
    color = get_color(data, port)
    port_state = port.enabled? ? state : 7

    state_description = case port.port_type
                        when 'reed_switch'
                          {
                            active: t(:opened),
                            passive: t(:closed)
                          }
                        when 'motion_sensor'
                          {
                            active: t(:motion_is_detected),
                            passive: t(:no_motion)
                          }
                        when 'leak_sensor'
                          {
                            active: t(:leak_is_detected),
                            passive: t(:no_leak)
                          }
                        when 'smoke_sensor'
                          {
                            active: t(:smoke_is_detected),
                            passive: t(:no_smoke)
                          }
                        end

    text = if port_state.zero?
             state_description[:passive]
           elsif port_state == 7
             t(:port_disabled)
           else
             state_description[:active]
           end

    {
      state: port_state,
      color: color,
      location_id: port.location_id,
      text: text,
      port_type: port.port_type,
      port_id: port.id
    }
  end

  def temperature_sensor(port, data)
    voltage = data['voltage_' + Port.port_numbers[port.port_number].to_s]
    state = data['state_' + Port.port_numbers[port.port_number].to_s]
    color = get_color(data, port)

    if port.enabled?
      port_state = state
      temperature = (((voltage.to_f * 10 / 4095) / 5 - 0.5) / 0.01).round(2)
    else
      port_state = 7
      temperature = t(:port_disabled)
    end

    {
      state: port_state,
      color: color,
      temperature: temperature,
      location_id: port.location_id,
      port_type: port.port_type,
      port_id: port.id
    }
  end

  def switch(port, data)
    state = data[port.port_number]
    color = get_color(data, port)
    port_state = port.enabled? ? state : 7

    if port_state.zero?
      text = t(:stopped)
      button_text = t(:switch_on)
    elsif port_state == 7
      text = t(:port_disabled)
      button_text = t(:port_disabled)
    else
      text = t(:started)
      button_text = t(:switch_off)
    end

    {
      state: port_state,
      color: color,
      location_id: port.location_id,
      text: text,
      button_text: button_text,
      port_type: port.port_type,
      port_id: port.id
    }
  end

  def arming_switch(port, data)
    state = data[port.port_number]
    color = get_color(data, port)
    port_state = port.enabled? ? state : 7

    if port_state == 'Arm'
      alias_state = 1
      text = t(:armed)
      button_text = t(:arm_off)
    elsif port_state == 'Disarm'
      alias_state = 0
      text = t(:disarmed)
      button_text = t(:arm_on)
    elsif port_state == 7
      alias_state = 7
      text = t(:port_disabled)
      button_text = t(:port_disabled)
    end
    {
      state: alias_state,
      color: color,
      location_id: port.location_id,
      text: text,
      button_text: button_text,
      port_type: port.port_type,
      port_id: port.id
    }
  end

  def controller_log(port, location, ports_with_ranges)
    if location == 'page'

      unless ports_with_ranges.blank?
        target_port = ports_with_ranges.find { |pwr| pwr[0] == port.id }
      end

      range = if !ports_with_ranges.blank? && target_port
                target_port[2].to_i
              else
                5
              end

      log = Log.where(connection_id: port.connection_id)
               .order(created_at: :desc).limit(range)

      records = [{ created_at: CGI.escapeHTML(t(:created_at)),
                   event_id: CGI.escapeHTML(t(:event_id)),
                   event_type: CGI.escapeHTML(t(:event_type)),
                   description: CGI.escapeHTML(t(:description)) }]
      log.each do |r|
        time = r.created_at + Time.now.utc_offset
        description = translate_message(r, port)
        records << { created_at: time.strftime('%H:%M:%S %d.%m.%y'),
                     event_id: CGI.escapeHTML(r.event_id.to_s),
                     event_type: CGI.escapeHTML(r.event_type),
                     description: CGI.escapeHTML(description) }
      end
    else
      records = 'no data'
    end

    {
      state: 0,
      location_id: port.location_id,
      records: records,
      title: port.name,
      text: t(:records_count),
      port_type: port.port_type,
      port_id: port.id
    }
  end

  def temperature_chart(port, location, ports_with_ranges)
    if location == 'page'
      unless ports_with_ranges.blank?
        target_port = ports_with_ranges.find { |pwr| pwr[0] == port.id }
      end

      range = if !ports_with_ranges.blank? &&
                 target_port &&
                 target_port[2].to_i > 0 &&
                 target_port[2].to_i <= 14
                target_port[2].to_i.days
              else
                1.day
              end

      voltage = 'voltage_' + Port.port_numbers[port.port_number].to_s
      raw_data = Record.where(connection_id: port.connection_id)
                       .where('created_at > ?', Time.now - range)
                       .where("#{voltage} > ?", 200)
                       .where("#{voltage} < ?", 3500)
                       .pluck(voltage, 'created_at') rescue nil

      chart_data = temperature_chart_data(raw_data) unless raw_data.blank?
    else
      chart_data = 'no data'
    end
    {
      state: 0,
      chart_data: chart_data,
      title: port.name,
      axis_y_title: t('temperature_chart.axis_y_title'),
      text: t(:select_days),
      location_id: port.location_id,
      port_type: port.port_type,
      port_id: port.id
    }
  end

  #=========================== Other methods ==================================

  def translate_message(record, port)
    if record.event_type == 'ProfileApplied'
      data = JSON.parse(record.description)
      t(:profile_was_applied) + data['Number'].to_s
    elsif record.event_type == 'Arm'
      data = JSON.parse(record.description)
      t(:partition_arm_on) + data['Partition'].to_s
    elsif record.event_type == 'Disarm'
      data = JSON.parse(record.description)
      t(:partition_arm_off) + data['Partition'].to_s
    elsif record.event_type == 'InputActive'
      data = JSON.parse(record.description)
      ports = Port.where(port_number: data['Number'],
                         location_id: port.location_id,
                         connection_id: record.connection_id)
      accepted_ports = ports.select do |p|
        port_group(p.port_type) == 'common_ports' &&
          (current_user.administrator? || p.access == current_user.role)
      end
      return t(:no_accepted_ports) if accepted_ports.blank?
      names = accepted_ports.map(&:name)
      t(:input_alert) + names.join('; ') + '.'
    elsif record.event_type == 'InputPassive'
      data = JSON.parse(record.description)
      ports = Port.where(port_number: data['Number'],
                         location_id: port.location_id,
                         connection_id: record.connection_id)
      accepted_ports = ports.select do |p|
        port_group(p.port_type) == 'common_ports' &&
          (current_user.administrator? || p.access == current_user.role)
      end
      return t(:no_accepted_ports) if accepted_ports.blank?
      names = accepted_ports.map(&:name)
      t(:input_passive) + names.join('; ') + '.'
    elsif record.event_type == 'CaseOpen'
      t(:open_case)
    elsif record.event_type == 'DeviceOn'
      t(:device_on)
    elsif record.event_type == 'DeviceRestart'
      t(:device_was_restarted)
    elsif record.event_type == 'PowerRecovery'
      t(:power_was_recovered)
    elsif record.event_type == 'Test'
      t(:test_message_from_device)
    else
      record.description
    end
  end

  def temperature_chart_data(data)
    data.each do |d|
      temperature = (((d[0].to_f * 10 / 4095) / 5 - 0.5) / 0.01).round(2)
      d[0] = temperature
    end
  end

  def voltage_chart_data(data)
    data.each { |d| d[0] = (d[0].to_f * 10 / 4095).round(2) }
  end

  def port_group(type)
    if %w[reed_switch motion_sensor leak_sensor smoke_sensor].include?(type)
      'common_ports'
    elsif %w[
      voltage_chart temperature_chart connection_checker controller_log
    ].include?(type)
      'special_ports'
    else
      'undefined'
    end
  end

  def get_color(data, p)
    return 'grey' unless p.enabled?
    color = 'info'
    if data
      range = Time.now - data.created_at
      color = 'warning' if p.before_warning != 0 && range >= p.before_warning
      color = 'danger' if p.before_alert != 0 && range >= p.before_alert
    end
    color
  end
end
