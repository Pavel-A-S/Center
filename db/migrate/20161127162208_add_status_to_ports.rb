class AddStatusToPorts < ActiveRecord::Migration
  def change
    add_column :ports, :state, :integer, default: 1
  end
end
