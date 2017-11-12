# Data setter
module DataSetter
  extend ActiveSupport::Concern

  def set_data(message, connection_id, identifier)
    data = JSON.parse message.body rescue 'nope'

    # Check for errors
    if data != 'nope' && data.is_a?(Hash) &&
       (%w[Inputs Outputs].all? { |key| data.key? key }) &&
       data['Inputs'].is_a?(Array) && data['Outputs'].is_a?(Array) &&
       data['Inputs'].length == 16 && data['Outputs'].length == 7

      @record = Record.new
      @record.connection_id = connection_id
      @record.controller_identifier = identifier
      @record.voltage_1 = data['Inputs'][0]['Voltage']
      @record.voltage_2 = data['Inputs'][1]['Voltage']
      @record.voltage_3 = data['Inputs'][2]['Voltage']
      @record.voltage_4 = data['Inputs'][3]['Voltage']
      @record.voltage_5 = data['Inputs'][4]['Voltage']
      @record.voltage_6 = data['Inputs'][5]['Voltage']
      @record.voltage_7 = data['Inputs'][6]['Voltage']
      @record.voltage_8 = data['Inputs'][7]['Voltage']
      @record.voltage_9 = data['Inputs'][8]['Voltage']
      @record.voltage_10 = data['Inputs'][9]['Voltage']
      @record.voltage_11 = data['Inputs'][10]['Voltage']
      @record.voltage_12 = data['Inputs'][11]['Voltage']
      @record.voltage_13 = data['Inputs'][12]['Voltage']
      @record.voltage_14 = data['Inputs'][13]['Voltage']
      @record.voltage_15 = data['Inputs'][14]['Voltage']
      @record.voltage_16 = data['Inputs'][15]['Voltage']
      @record.state_1 = data['Inputs'][0]['Active']
      @record.state_2 = data['Inputs'][1]['Active']
      @record.state_3 = data['Inputs'][2]['Active']
      @record.state_4 = data['Inputs'][3]['Active']
      @record.state_5 = data['Inputs'][4]['Active']
      @record.state_6 = data['Inputs'][5]['Active']
      @record.state_7 = data['Inputs'][6]['Active']
      @record.state_8 = data['Inputs'][7]['Active']
      @record.state_9 = data['Inputs'][8]['Active']
      @record.state_10 = data['Inputs'][9]['Active']
      @record.state_11 = data['Inputs'][10]['Active']
      @record.state_12 = data['Inputs'][11]['Active']
      @record.state_13 = data['Inputs'][12]['Active']
      @record.state_14 = data['Inputs'][13]['Active']
      @record.state_15 = data['Inputs'][14]['Active']
      @record.state_16 = data['Inputs'][15]['Active']
      @record.output_1 = data['Outputs'][0]
      @record.output_2 = data['Outputs'][1]
      @record.output_3 = data['Outputs'][2]
      @record.output_4 = data['Outputs'][3]
      @record.output_5 = data['Outputs'][4]
      @record.output_6 = data['Outputs'][5]
      @record.output_7 = data['Outputs'][6]
      @record.profile = data['Case']
      @record.temp = data['Temp']
      @record.power = data['Power']
      @record.partition_1 = data['Partitions'][0]
      @record.partition_2 = data['Partitions'][1]
      @record.partition_3 = data['Partitions'][2]
      @record.partition_4 = data['Partitions'][3]
      @record.battery_state = data['Battery']['State']
      @record.balance = data['Balance']
      @record.full_message = data
      @record.save
      return @record
    else
      return data
    end
  end
end
