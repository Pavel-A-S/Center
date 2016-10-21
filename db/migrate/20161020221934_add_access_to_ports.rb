class AddAccessToPorts < ActiveRecord::Migration
  def change
    add_column :ports, :access, :integer
  end
end
