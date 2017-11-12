class AddExtraPortNumberToPorts < ActiveRecord::Migration
  def change
    add_column :ports, :extra_port_number, :integer
  end
end
