class AddTagCodeToPetTags < ActiveRecord::Migration[7.2]
  ALPHABET = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789".freeze

  class PetTagRecord < ActiveRecord::Base
    self.table_name = "pet_tags"
  end

  def up
    add_column :pet_tags, :tag_code, :string
    PetTagRecord.reset_column_information

    PetTagRecord.find_each do |pet_tag|
      pet_tag.update_columns(tag_code: next_tag_code)
    end

    change_column_null :pet_tags, :tag_code, false
    add_index :pet_tags, :tag_code, unique: true
  end

  def down
    remove_index :pet_tags, :tag_code
    remove_column :pet_tags, :tag_code
  end

  private

  def next_tag_code
    loop do
      raw = Array.new(8) { ALPHABET[SecureRandom.random_number(ALPHABET.length)] }.join
      code = "PJT-#{raw.first(4)}-#{raw.last(4)}"
      return code unless PetTagRecord.exists?(tag_code: code)
    end
  end
end
