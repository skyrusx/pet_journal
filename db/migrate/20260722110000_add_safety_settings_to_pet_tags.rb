class AddSafetySettingsToPetTags < ActiveRecord::Migration[7.2]
  def change
    add_column :pet_tags, :notification_preference, :integer, null: false, default: 1
    add_column :pet_tags, :token_rotated_at, :datetime
  end
end
