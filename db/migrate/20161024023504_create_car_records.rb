class CreateCarRecords < ActiveRecord::Migration
  def change
    create_table :car_records do |t|

      t.datetime :date
      t.string :first_name
      t.string :middle_name
      t.string :last_name
      t.string :initiator
      t.string :document_type
      t.string :document_number
      t.date :date_of_issue
      t.text :document_description
      t.string :car_number
      t.string :car_model
      t.text :cargo
      t.text :description
      t.integer :user_id

      t.timestamps null: false

    end
  end
end
