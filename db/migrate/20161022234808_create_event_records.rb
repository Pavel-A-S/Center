class CreateEventRecords < ActiveRecord::Migration
  def change
    create_table :event_records do |t|
      t.integer :user_id
      t.text :description

      t.timestamps null: false
    end
  end
end
