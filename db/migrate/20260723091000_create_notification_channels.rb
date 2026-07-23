class CreateNotificationChannels < ActiveRecord::Migration[7.2]
  def change
    create_table :notification_channels do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :channel_type, null: false
      t.string :name, null: false
      t.string :address
      t.boolean :enabled, null: false, default: true
      t.datetime :verified_at
      t.jsonb :settings, null: false, default: {}

      t.timestamps
    end

    add_index :notification_channels, %i[user_id channel_type]
  end
end
