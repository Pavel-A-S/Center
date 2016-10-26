class AddBeforeWarningAndBeforeAlertFieldsToPorts < ActiveRecord::Migration
  def change
    add_column :ports, :before_warning, :integer
    add_column :ports, :before_alert, :integer
  end
end
