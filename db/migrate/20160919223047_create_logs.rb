class CreateLogs < ActiveRecord::Migration
  def change
    create_table :logs do |t|
      t.string :controller_identifier
      t.integer :connection_id
      t.integer :event_id
      t.string :event_type
      t.string :description

      t.timestamps null: false
    end
  end
end
