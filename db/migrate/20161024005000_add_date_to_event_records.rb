class AddDateToEventRecords < ActiveRecord::Migration
  def change
    add_column :event_records, :date, :datetime
  end
end
