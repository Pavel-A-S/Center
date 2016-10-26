class CreateConnectionLogs < ActiveRecord::Migration
  def change
    create_table :connection_logs do |t|
      t.string :controller_identifier
      t.integer :connection_id
      t.string :message

      t.timestamps null: false
    end
  end
end
