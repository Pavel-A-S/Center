class CreatePorts < ActiveRecord::Migration
  def change
    create_table :ports do |t|
      t.string :name
      t.integer :port_number
      t.integer :port_type
      t.integer :location_id
      t.integer :connection_id
      t.text :description
      t.integer :order_index

      t.timestamps null: false
    end
  end
end
