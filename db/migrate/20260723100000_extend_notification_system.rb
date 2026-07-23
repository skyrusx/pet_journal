class ExtendNotificationSystem < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :notifications_quiet_hours_enabled, :boolean, null: false, default: false
    add_column :users, :notifications_quiet_hours_start, :time, null: false, default: "22:00"
    add_column :users, :notifications_quiet_hours_end, :time, null: false, default: "08:00"
    add_column :users, :notifications_time_zone, :string, null: false, default: "UTC"

    add_column :notification_deliveries, :attempts_count, :integer, null: false, default: 0
    add_column :notification_deliveries, :next_attempt_at, :datetime
    add_index :notification_deliveries, %i[status next_attempt_at]

    create_table :reminder_notification_channels do |t|
      t.references :reminder, null: false, foreign_key: true
      t.references :notification_channel, null: false, foreign_key: true

      t.timestamps
    end

    add_index :reminder_notification_channels,
              %i[reminder_id notification_channel_id],
              unique: true,
              name: "index_reminder_channels_on_reminder_and_channel"
  end
end
