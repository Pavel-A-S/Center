class CreateConnections < ActiveRecord::Migration
  def change
    create_table :connections do |t|
      t.string :name
      t.string :login
      t.string :password
      t.text :description
      t.integer :frequency
      t.string :identifier
      t.integer :time_out
      t.boolean :update_me

      t.timestamps null: false
    end
  end
end
