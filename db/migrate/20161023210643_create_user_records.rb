class CreateUserRecords < ActiveRecord::Migration
  def change
    create_table :user_records do |t|
      t.datetime :date
      t.string :first_name
      t.string :middle_name
      t.string :last_name
      t.string :initiator
      t.string :document_type
      t.string :document_number
      t.date :date_of_issue
      t.text :document_description
      t.text :description

      t.timestamps null: false
    end
  end
end
