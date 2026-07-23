class CreateNotificationDeliveries < ActiveRecord::Migration[7.2]
  def change
    create_table :notification_deliveries do |t|
      t.references :reminder, null: false, foreign_key: true
      t.references :notification_channel, null: false, foreign_key: true
      t.integer :status, null: false, default: 0
      t.datetime :delivered_at
      t.text :error_message

      t.timestamps
    end

    add_index :notification_deliveries, %i[reminder_id notification_channel_id created_at],
              name: "index_deliveries_on_reminder_channel_created_at"
  end
end
