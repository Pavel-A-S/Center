class CreateRecords < ActiveRecord::Migration
  def change
    create_table :records do |t|
      t.integer :connection_id
      t.string :controller_identifier
      t.integer :voltage_1
      t.integer :voltage_2
      t.integer :voltage_3
      t.integer :voltage_4
      t.integer :voltage_5
      t.integer :voltage_6
      t.integer :voltage_7
      t.integer :voltage_8
      t.integer :voltage_9
      t.integer :voltage_10
      t.integer :voltage_11
      t.integer :voltage_12
      t.integer :voltage_13
      t.integer :voltage_14
      t.integer :voltage_15
      t.integer :voltage_16
      t.integer :state_1
      t.integer :state_2
      t.integer :state_3
      t.integer :state_4
      t.integer :state_5
      t.integer :state_6
      t.integer :state_7
      t.integer :state_8
      t.integer :state_9
      t.integer :state_10
      t.integer :state_11
      t.integer :state_12
      t.integer :state_13
      t.integer :state_14
      t.integer :state_15
      t.integer :state_16
      t.integer :output_1
      t.integer :output_2
      t.integer :output_3
      t.integer :output_4
      t.integer :output_5
      t.integer :output_6
      t.integer :output_7
      t.integer :profile
      t.integer :temp
      t.decimal :power, precision: 14, scale: 2
      t.string :partition_1
      t.string :partition_2
      t.string :partition_3
      t.string :partition_4
      t.string :battery_state
      t.string :balance
      t.text :full_message

      t.timestamps null: false
    end
  end
end
