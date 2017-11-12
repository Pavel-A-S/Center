# Port model
class Port < ActiveRecord::Base
  belongs_to :location
  belongs_to :connection

  enum port_type: %w[
    reed_switch motion_sensor temperature_sensor leak_sensor switch
    arming_switch temperature_chart connection_checker smoke_sensor
    controller_log pressure_sensor controller_raw_data voltage_chart
  ]
  enum port_number: {
    in1: 1, in2: 2, in3: 3, in4: 4, in5: 5, in6: 6, in7: 7, in8: 8, in9: 9,
    in10: 10, in11: 11, in12: 12, in13: 13, in14: 14, in15: 15, in16: 16,
    output_1: 51, output_2: 52, output_3: 53, output_4: 54, output_5: 55,
    output_6: 56, output_7: 57,
    partition_1: 101, partition_2: 102, partition_3: 103, partition_4: 104
  }

  enum extra_port_number: {
    extra_in1: 1, extra_in2: 2, extra_in3: 3, extra_in4: 4, extra_in5: 5,
    extra_in6: 6, extra_in7: 7, extra_in8: 8, extra_in9: 9, extra_in10: 10,
    extra_in11: 11, extra_in12: 12, extra_in13: 13, extra_in14: 14,
    extra_in15: 15, extra_in16: 16
  }

  enum icon: %i[
    door eye siren chart temperature water signal fire electricity door_lock
    journal pressure wrench
  ]

  enum access: %i[security engineer administrator]

  enum state: %i[disabled enabled]

  validates :name, presence: true, length: { maximum: 250 }
  validates :order_index, numericality: { greater_than: -100_000,
                                          less_than: 100_000 }
  validates :before_warning, numericality: { greater_than: -1,
                                             less_than: 100_000 }
  validates :before_alert, numericality: { greater_than: -1,
                                           less_than: 100_000 }

  def port_type_1?
    %w[
      temperature_sensor reed_switch motion_sensor leak_sensor
      connection_checker smoke_sensor pressure_sensor
    ].include?(port_type)
  end

  def port_type_2?
    %w[switch arming_switch].include?(port_type)
  end
end
