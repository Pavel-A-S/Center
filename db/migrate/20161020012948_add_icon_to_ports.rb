class AddIconToPorts < ActiveRecord::Migration
  def change
    add_column :ports, :icon, :integer
  end
end
