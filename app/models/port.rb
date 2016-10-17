class Port < ActiveRecord::Base
  belongs_to :location
  belongs_to :connection

  enum port_type: ['reed_switch', 'motion_sensor', 'temperature_sensor',
                                                   'leak_sensor',
                                                   'switch',
                                                   'temperature_chart',
                                                   'connection_checker']
  enum port_number: { in1: 1, in2: 2, in3: 3, in4: 4, in5: 5, in6: 6, in7: 7,
                      in8: 8,
                      output_1: 11, output_2: 12, output_3: 13, output_4: 14,
                      output_5: 15, output_6: 16, output_7: 17 }
end
