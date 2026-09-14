require "test_helper"

class PetPhotoManagerTest < ActiveSupport::TestCase
  setup do
    @pet = pets(:one)
    @pet.pet_photos.destroy_all
    @pet.photo.detach if @pet.photo.attached?
    @manager = PetPhotoManager.new(@pet)
  end

  test "first uploaded photo becomes primary" do
    photos = @manager.add!([image_upload("one.jpg"), image_upload("two.jpg")])

    assert_equal 2, photos.size
    assert photos.first.reload.is_primary?
    assert_not photos.second.reload.is_primary?
    assert_equal [0, 1], @pet.pet_photos.ordered.pluck(:position)
  end

  test "changing primary keeps one primary photo and updates legacy attachment" do
    first, second = @manager.add!([image_upload("one.jpg"), image_upload("two.jpg")])

    @manager.make_primary!(second, valid_crop)

    assert_not first.reload.is_primary?
    assert second.reload.is_primary?
    assert_equal 1, @pet.pet_photos.where(is_primary: true).count

    legacy = ActiveStorage::Attachment.find_by(record_type: "Pet", record_id: @pet.id, name: "photo")
    assert_equal second.image.blob_id, legacy.blob_id
  end

  test "removing primary promotes the next ordered photo" do
    first, second = @manager.add!([image_upload("one.jpg"), image_upload("two.jpg")])

    @manager.remove!(first)

    assert second.reload.is_primary?
    assert_equal 0, second.position
  end

  test "reorders all photos" do
    first, second, third = @manager.add!(
      [image_upload("one.jpg"), image_upload("two.jpg"), image_upload("three.jpg")]
    )

    @manager.reorder!([third.id, first.id, second.id])

    assert_equal [third.id, first.id, second.id], @pet.pet_photos.ordered.pluck(:id)
  end

  test "rejects reorder with a partial gallery" do
    first, = @manager.add!([image_upload("one.jpg"), image_upload("two.jpg")])

    error = assert_raises(PetPhotoManager::Error) { @manager.reorder!([first.id]) }

    assert_match(/Состав галереи изменился/, error.message)
  end

  private

  def image_upload(filename)
    {
      io: StringIO.new("fake jpeg #{filename}"),
      filename: filename,
      content_type: "image/jpeg",
      identify: false
    }
  end

  def valid_crop
    {
      avatar_crop_x: 0.1,
      avatar_crop_y: 0.1,
      avatar_crop_width: 0.7,
      avatar_crop_height: 0.7
    }
  end
end
