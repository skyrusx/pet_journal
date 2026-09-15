require "test_helper"
require "base64"
require "tempfile"

class PetPhotosControllerTest < ActionDispatch::IntegrationTest
  PNG_1X1 = Base64.decode64(
    "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII="
  ).freeze

  setup do
    @user = users(:one)
    @pet = pets(:one)
    sign_in @user

    @pet.pet_photos.destroy_all
    @pet.photo.detach if @pet.photo.attached?
    @tempfiles = []
  end

  teardown do
    @tempfiles.each do |file|
      file.close
      file.unlink
    rescue Errno::ENOENT
      nil
    end
  end

  test "uploads photos and makes the first one profile photo" do
    assert_difference("@pet.pet_photos.count", 2) do
      post pet_pet_photos_url(@pet),
           params: { images: [uploaded_png("one.png"), uploaded_png("two.png")] },
           headers: json_headers
    end

    assert_response :created
    assert @pet.reload.primary_photo.present?
    assert_equal 1, @pet.pet_photos.where(is_primary: false).count
  end

  test "selects profile photo with crop coordinates" do
    first, second = create_photos(2)
    crop = {
      avatar_crop_x: 0.1,
      avatar_crop_y: 0.15,
      avatar_crop_width: 0.7,
      avatar_crop_height: 0.7
    }

    patch primary_pet_pet_photo_url(@pet, second),
          params: { pet_photo: crop },
          headers: json_headers

    assert_response :success
    assert_not first.reload.is_primary?
    assert second.reload.is_primary?
    assert_in_delta 0.1, second.avatar_crop_x, 0.0001
    assert_in_delta 0.15, second.avatar_crop_y, 0.0001
  end

  test "updates crop without changing profile photo" do
    primary, = create_photos(2)

    patch crop_pet_pet_photo_url(@pet, primary),
          params: {
            pet_photo: {
              avatar_crop_x: 0.2,
              avatar_crop_y: 0.1,
              avatar_crop_width: 0.6,
              avatar_crop_height: 0.6
            }
          },
          headers: json_headers

    assert_response :success
    assert primary.reload.is_primary?
    assert_in_delta 0.2, primary.avatar_crop_x, 0.0001
  end

  test "reorders only gallery photos" do
    primary, second, third = create_photos(3)

    patch reorder_pet_pet_photos_url(@pet),
          params: { photo_ids: [third.id, second.id] },
          headers: json_headers

    assert_response :no_content
    assert_equal 0, primary.reload.position
    assert_equal [third.id, second.id], @pet.pet_photos.where(is_primary: false).ordered.pluck(:id)
  end

  test "rejects incomplete reorder payload" do
    _primary, second, = create_photos(3)

    patch reorder_pet_pet_photos_url(@pet),
          params: { photo_ids: [second.id] },
          headers: json_headers

    assert_response :unprocessable_entity
    assert_match(/Состав галереи изменился/, response.parsed_body.fetch("error"))
  end

  test "deleting profile photo keeps gallery photos" do
    primary, second, third = create_photos(3)

    assert_difference("@pet.pet_photos.count", -1) do
      delete pet_pet_photo_url(@pet, primary), headers: json_headers
    end

    assert_response :success
    assert_nil @pet.reload.primary_photo
    assert_equal [second.id, third.id], @pet.pet_photos.ordered.pluck(:id)
  end

  test "cannot manage another users pet photos" do
    other_pet = pets(:two)
    other_pet.pet_photos.destroy_all
    other_photo = PetPhotoManager.new(other_pet).add!([image_upload_hash("other.png")]).first

    delete pet_pet_photo_url(other_pet, other_photo), headers: json_headers

    assert_response :not_found
    assert PetPhoto.exists?(other_photo.id)
  end

  private

  def create_photos(count)
    uploads = Array.new(count) { |index| image_upload_hash("photo-#{index}.png") }
    PetPhotoManager.new(@pet).add!(uploads)
  end

  def image_upload_hash(filename)
    {
      io: StringIO.new(PNG_1X1),
      filename: filename,
      content_type: "image/png",
      identify: false
    }
  end

  def uploaded_png(filename)
    tempfile = Tempfile.new([File.basename(filename, ".png"), ".png"])
    tempfile.binmode
    tempfile.write(PNG_1X1)
    tempfile.rewind
    @tempfiles << tempfile

    ActionDispatch::Http::UploadedFile.new(
      tempfile: tempfile,
      filename: filename,
      type: "image/png"
    )
  end

  def json_headers
    { "ACCEPT" => "application/json" }
  end
end
