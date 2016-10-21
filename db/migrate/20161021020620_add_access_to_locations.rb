class AddAccessToLocations < ActiveRecord::Migration
  def change
    add_column :locations, :access, :integer
  end
end
