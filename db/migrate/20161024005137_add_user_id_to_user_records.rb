class AddUserIdToUserRecords < ActiveRecord::Migration
  def change
    add_column :user_records, :user_id, :integer
  end
end
