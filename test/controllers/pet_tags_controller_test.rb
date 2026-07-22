require "test_helper"

class PetTagsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @pet = pets(:one)
    @pet_tag = pet_tags(:one)
    sign_in @user
  end

  test "should show pet tag" do
    get pet_pet_tag_url(@pet)

    assert_response :success
  end

  test "should create pet tag" do
    pet = @user.pets.create!(name: "Без жетона")

    assert_difference("PetTag.count") do
      post pet_pet_tag_url(pet), params: {
        pet_tag: {
          public_message: "Позвоните владельцу.",
          behavior_notes: "Боится шума.",
          medical_notes: "Без лекарств.",
          contact_phone: "+79990000003",
          show_phone: "1"
        }
      }
    end

    assert_redirected_to pet_pet_tag_url(pet)
    assert pet.reload.pet_tag.public_token.present?
  end

  test "should get edit" do
    get edit_pet_pet_tag_url(@pet)

    assert_response :success
  end

  test "should update pet tag" do
    patch pet_pet_tag_url(@pet), params: {
      pet_tag: {
        public_message: "Новое публичное сообщение",
        lost_mode_enabled: "0",
        show_phone: "0"
      }
    }

    assert_redirected_to pet_pet_tag_url(@pet)
    assert_equal "Новое публичное сообщение", @pet_tag.reload.public_message
    assert_not @pet_tag.show_phone?
  end

  test "should update lost mode fields" do
    patch pet_pet_tag_url(@pet), params: {
      pet_tag: {
        lost_mode_enabled: "1",
        lost_message: "Питомец потерялся, позвоните сразу.",
        last_seen_location: "Сквер у школы"
      }
    }

    assert_redirected_to pet_pet_tag_url(@pet)
    assert @pet_tag.reload.lost_mode_enabled?
    assert_equal "Питомец потерялся, позвоните сразу.", @pet_tag.lost_message
    assert_equal "Сквер у школы", @pet_tag.last_seen_location
  end
end
