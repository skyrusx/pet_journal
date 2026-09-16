class CreatePetPhotos < ActiveRecord::Migration[7.2]
  class MigrationPet < ActiveRecord::Base
    self.table_name = "pets"
  end

  class MigrationPetPhoto < ActiveRecord::Base
    self.table_name = "pet_photos"
  end

  class MigrationAttachment < ActiveRecord::Base
    self.table_name = "active_storage_attachments"
  end

  def up
    create_table :pet_photos do |t|
      t.references :pet, null: false, foreign_key: true
      t.integer :position, null: false, default: 0
      t.boolean :is_primary, null: false, default: false
      t.float :avatar_crop_x
      t.float :avatar_crop_y
      t.float :avatar_crop_width
      t.float :avatar_crop_height

      t.timestamps
    end

    add_index :pet_photos, %i[pet_id position]
    add_index :pet_photos,
              :pet_id,
              unique: true,
              where: "is_primary",
              name: "index_pet_photos_on_primary_pet"

    backfill_existing_photos
  end

  def down
    MigrationAttachment.where(record_type: "PetPhoto", name: "image").delete_all
    drop_table :pet_photos
  end

  private

  def backfill_existing_photos
    MigrationAttachment.where(record_type: "Pet", name: "photo").find_each do |attachment|
      next unless MigrationPet.where(id: attachment.record_id).exists?

      pet_photo = MigrationPetPhoto.create!(
        pet_id: attachment.record_id,
        position: 0,
        is_primary: true,
        created_at: attachment.created_at || Time.current,
        updated_at: attachment.created_at || Time.current
      )

      MigrationAttachment.create!(
        name: "image",
        record_type: "PetPhoto",
        record_id: pet_photo.id,
        blob_id: attachment.blob_id,
        created_at: attachment.created_at || Time.current
      )
    end
  end
end
