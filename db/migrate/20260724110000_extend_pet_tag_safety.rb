class ExtendPetTagSafety < ActiveRecord::Migration[7.2]
  def change
    add_column :pet_tags, :safety_status, :integer, null: false, default: 0
    add_column :pet_tags, :show_medical_notes, :boolean, null: false, default: true
    add_column :pet_tags, :found_message, :text
    add_column :pet_tags, :reunited_at, :datetime

    add_column :pet_tag_scans, :scan_status, :integer, null: false, default: 0
    add_column :pet_tag_scans, :finder_name, :string
    add_column :pet_tag_scans, :finder_contact, :string
    add_column :pet_tag_scans, :finder_message, :text
    add_column :pet_tag_scans, :found_reported_at, :datetime
    add_column :pet_tag_scans, :owner_notified_at, :datetime
    add_column :pet_tag_scans, :notification_error, :text

    create_table :pet_tag_notification_channels do |t|
      t.references :pet_tag, null: false, foreign_key: true
      t.references :notification_channel, null: false, foreign_key: true

      t.timestamps
    end

    add_index :pet_tag_notification_channels,
              %i[pet_tag_id notification_channel_id],
              unique: true,
              name: "index_pet_tag_channels_on_tag_and_channel"
    add_index :pet_tag_scans, %i[pet_tag_id scan_status created_at]
  end
end
