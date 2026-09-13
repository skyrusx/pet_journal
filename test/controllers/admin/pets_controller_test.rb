require "test_helper"

class Admin::PetsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:admin)
  end

  test "lists pets" do
    get admin_pets_path

    assert_response :success
    assert_select "h1", "Питомцы"
    assert_select "body", text: /owner_one@example.com/
    assert_select "body", text: /owner_two@example.com/
  end

  test "searches pets by owner email" do
    get admin_pets_path, params: { q: "owner_one" }

    assert_response :success
    assert_select "body", text: /owner_one@example.com/
    assert_select "body", text: /owner_two@example.com/, count: 0
  end

  test "filters lost pets" do
    get admin_pets_path, params: { lost: "1" }

    assert_response :success
    assert_select "body", text: /owner_one@example.com/
    assert_select "body", text: /owner_two@example.com/, count: 0
  end

  test "shows pet" do
    pet = pets(:one)

    get admin_pet_path(pet)

    assert_response :success
    assert_select "body", text: /#{Regexp.escape(pet.name)}/
    assert_select "body", text: /owner_one@example.com/
  end
end
