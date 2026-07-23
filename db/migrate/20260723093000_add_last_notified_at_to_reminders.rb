class AddLastNotifiedAtToReminders < ActiveRecord::Migration[7.2]
  def change
    add_column :reminders, :last_notified_at, :datetime
    add_index :reminders, :last_notified_at
  end
end
