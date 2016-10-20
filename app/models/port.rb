class Port < ActiveRecord::Base
  belongs_to :location
  belongs_to :connection

  enum port_type: ['reed_switch', 'motion_sensor', 'temperature_sensor',
                                                   'leak_sensor',
                                                   'switch',
                                                   'temperature_chart',
                                                   'connection_checker']
  enum port_number: { in1: 1, in2: 2, in3: 3, in4: 4, in5: 5, in6: 6, in7: 7,
                      in8: 8, in9: 9, in10: 10, in11: 11, in12: 12, in13: 13,
                      in14: 14, in15: 15, in16: 16,
                      output_1: 51, output_2: 52, output_3: 53, output_4: 54,
                      output_5: 55, output_6: 56, output_7: 57 }

  enum icon: [:door, :eye, :siren, :chart, :temperature, :water, :signal, :fire]

  validates :name, presence: true, length: { maximum: 250 }
  validates :order_index, numericality: { greater_than: -100000,
                                          less_than: 100000 }
end
