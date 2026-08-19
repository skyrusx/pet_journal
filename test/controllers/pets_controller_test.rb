require "test_helper"

class PetsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @pet = pets(:one)
    sign_in @user
  end

  test "should get index" do
    get pets_url

    assert_response :success
    assert_select ".home-hero"
    assert_select ".home-pet-card", minimum: 1
  end

  test "should show pet" do
    get pet_url(@pet)

    assert_response :success
    assert_select ".dashboard-hero"
    assert_select ".pet-focus-card", count: 2
    assert_select ".dashboard-section", text: /Публичный доступ/
    assert_select ".dashboard-section", text: /PetTag/
  end

  test "should get new" do
    get new_pet_url

    assert_response :success
  end

  test "should create pet" do
    assert_difference("Pet.count") do
      post pets_url, params: {
        pet: {
          name: "Марс",
          species: "Кот",
          breed: "Метис",
          weight: 4.8
        }
      }
    end

    assert_redirected_to pet_url(Pet.order(:created_at).last)
  end

  test "should get edit" do
    get edit_pet_url(@pet)

    assert_response :success
  end

  test "should update pet" do
    patch pet_url(@pet), params: { pet: { name: "Обновленное имя" } }

    assert_redirected_to pet_url(@pet)
    assert_equal "Обновленное имя", @pet.reload.name
  end
end
