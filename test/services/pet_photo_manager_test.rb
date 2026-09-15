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

  test "changing primary swaps profile photo into selected gallery slot" do
    first, second, third = @manager.add!(
      [image_upload("one.jpg"), image_upload("two.jpg"), image_upload("three.jpg")]
    )

    @manager.make_primary!(third, valid_crop)

    assert_not first.reload.is_primary?
    assert third.reload.is_primary?
    assert_equal 0, third.position
    assert_equal 2, first.position
    assert_equal [second.id, first.id], @pet.pet_photos.where(is_primary: false).ordered.pluck(:id)
    assert_equal 1, @pet.pet_photos.where(is_primary: true).count

    legacy = ActiveStorage::Attachment.find_by(record_type: "Pet", record_id: @pet.id, name: "photo")
    assert_equal third.image.blob_id, legacy.blob_id
  end

  test "removing profile photo keeps gallery intact and leaves no profile photo" do
    first, second, third = @manager.add!(
      [image_upload("one.jpg"), image_upload("two.jpg"), image_upload("three.jpg")]
    )

    @manager.remove!(first)

    assert_nil @pet.reload.primary_photo
    assert_equal 0, @pet.pet_photos.where(is_primary: true).count
    assert_equal [second.id, third.id], @pet.pet_photos.where(is_primary: false).ordered.pluck(:id)
    assert_equal [0, 1], @pet.pet_photos.where(is_primary: false).ordered.pluck(:position)
    assert_nil ActiveStorage::Attachment.find_by(record_type: "Pet", record_id: @pet.id, name: "photo")
  end

  test "reorders gallery photos without including profile photo" do
    first, second, third = @manager.add!(
      [image_upload("one.jpg"), image_upload("two.jpg"), image_upload("three.jpg")]
    )

    @manager.reorder!([third.id, second.id])

    assert first.reload.is_primary?
    assert_equal 0, first.position
    assert_equal [third.id, second.id], @pet.pet_photos.where(is_primary: false).ordered.pluck(:id)
    assert_equal [1, 2], @pet.pet_photos.where(is_primary: false).ordered.pluck(:position)
  end

  test "reorders gallery from zero when profile photo was removed" do
    first, second, third = @manager.add!(
      [image_upload("one.jpg"), image_upload("two.jpg"), image_upload("three.jpg")]
    )
    @manager.remove!(first)

    @manager.reorder!([third.id, second.id])

    assert_equal [third.id, second.id], @pet.pet_photos.ordered.pluck(:id)
    assert_equal [0, 1], @pet.pet_photos.ordered.pluck(:position)
  end

  test "rejects reorder with an incomplete gallery" do
    _first, second, = @manager.add!(
      [image_upload("one.jpg"), image_upload("two.jpg"), image_upload("three.jpg")]
    )

    error = assert_raises(PetPhotoManager::Error) { @manager.reorder!([second.id]) }

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
