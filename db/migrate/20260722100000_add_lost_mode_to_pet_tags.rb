class AddLostModeToPetTags < ActiveRecord::Migration[7.2]
  def change
    add_column :pet_tags, :lost_mode_enabled, :boolean, null: false, default: false
    add_column :pet_tags, :lost_message, :text
    add_column :pet_tags, :last_seen_location, :string
  end
end
