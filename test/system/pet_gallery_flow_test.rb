require "application_system_test_case"
require "base64"

class PetGalleryFlowTest < ApplicationSystemTestCase
  PNG_1X1 = Base64.decode64(
    "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII="
  ).freeze

  setup do
    @user = users(:one)
    @pet = pets(:one)
    @pet.pet_photos.destroy_all
    @pet.photo.detach if @pet.photo.attached?
    PetPhotoManager.new(@pet).add!(3.times.map { |index| image_upload("gallery-#{index}.png") })
  end

  test "owner can choose profile photo crop it and browse gallery" do
    sign_in_through_ui

    visit edit_pet_path(@pet)
    assert_selector "[data-pet-gallery-card]", count: 2

    find("[data-pet-crop-trigger][data-mode='primary']", match: :first).click
    assert_selector "[data-pet-crop-modal]:not([hidden])", visible: true
    assert_text "Выберите область фото"
    find("[data-pet-crop-save]").click

    assert_selector ".pj-pet-main-photo__preview", visible: true
    assert_selector ".pj-pet-main-photo__preview img[data-pet-avatar-crop='true']", count: 1
    assert_selector "[data-pet-gallery-card]", count: 2

    visit pet_path(@pet)
    assert_selector ".pj-pet-gallery-view__item", count: 2

    find(".pj-pet-gallery-view__item", match: :first).click
    assert_selector "[data-pet-lightbox]:not([hidden])", visible: true
    assert_text "1 / 2"

    page.send_keys(:arrow_right)
    assert_text "2 / 2"

    find("[data-pet-lightbox]:not([hidden]) .pj-pet-lightbox__backdrop", visible: true).click
    assert_no_selector "[data-pet-lightbox]:not([hidden])", visible: true

    find(".pj-pet-profile-avatar").click
    assert_selector "[data-pet-profile-lightbox]:not([hidden])", visible: true
    find("[data-pet-profile-lightbox] .pj-pet-lightbox__backdrop", visible: true).click
    assert_no_selector "[data-pet-profile-lightbox]:not([hidden])", visible: true
  end

  private

  def image_upload(filename)
    {
      io: StringIO.new(PNG_1X1),
      filename: filename,
      content_type: "image/png",
      identify: false
    }
  end

  def sign_in_through_ui
    visit new_user_session_path
    fill_in "user_email", with: @user.email
    fill_in "user_password", with: "password123"
    click_button "Войти"
    assert_current_path root_path
  end
end
