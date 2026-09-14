require "test_helper"

class PetPhotoTest < ActiveSupport::TestCase
  setup do
    @pet = pets(:one)
    @pet.pet_photos.destroy_all
  end

  test "accepts a supported image" do
    photo = @pet.pet_photos.build(position: 0, is_primary: true)
    photo.image.attach(image_upload("pet.jpg"))

    assert photo.valid?
  end

  test "rejects an unsupported image type" do
    photo = @pet.pet_photos.build(position: 0)
    photo.image.attach(
      io: StringIO.new("document"),
      filename: "pet.pdf",
      content_type: "application/pdf",
      identify: false
    )

    assert_not photo.valid?
    assert_includes photo.errors[:image], "должно быть JPEG, PNG или WebP"
  end

  test "accepts normalized avatar crop coordinates" do
    photo = create_photo
    photo.assign_attributes(
      avatar_crop_x: 0.15,
      avatar_crop_y: 0.1,
      avatar_crop_width: 0.6,
      avatar_crop_height: 0.8
    )

    assert photo.valid?
    assert photo.avatar_crop?
  end

  test "rejects crop outside image bounds" do
    photo = create_photo
    photo.assign_attributes(
      avatar_crop_x: 0.7,
      avatar_crop_y: 0.1,
      avatar_crop_width: 0.5,
      avatar_crop_height: 0.5
    )

    assert_not photo.valid?
    assert_includes photo.errors[:base], "Область аватара выходит за границы фотографии"
  end

  private

  def create_photo
    photo = @pet.pet_photos.build(position: 0, is_primary: true)
    photo.image.attach(image_upload("pet.jpg"))
    photo.save!
    photo
  end

  def image_upload(filename)
    {
      io: StringIO.new("fake jpeg #{filename}"),
      filename: filename,
      content_type: "image/jpeg",
      identify: false
    }
  end
end
