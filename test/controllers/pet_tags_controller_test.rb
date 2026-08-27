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

  test "should create pet tag with public phone forced off" do
    pet = @user.pets.create!(name: "Без жетона")

    assert_difference("PetTag.count") do
      post pet_pet_tag_url(pet), params: {
        pet_tag: {
          public_message: "Свяжитесь с владельцем.",
          behavior_notes: "Боится шума.",
          medical_notes: "Без лекарств.",
          contact_phone: "+79990000003",
          show_phone: "1"
        }
      }
    end

    assert_redirected_to pet_pet_tag_url(pet)
    assert pet.reload.pet_tag.public_token.present?
    assert_not pet.pet_tag.show_phone?
  end

  test "should get edit and explain public phone restriction" do
    get edit_pet_pet_tag_url(@pet)

    assert_response :success
    assert_select "input[name='pet_tag[show_phone]'][type='hidden'][value='0']", minimum: 1
    assert_select "[aria-disabled='true']", text: /Публичный телефон отключён/
  end

  test "should update pet tag" do
    patch pet_pet_tag_url(@pet), params: {
      pet_tag: {
        public_message: "Новое публичное сообщение",
        safety_status: "safe",
        show_phone: "1",
        show_medical_notes: "0",
        notification_preference: "always"
      }
    }

    assert_redirected_to pet_pet_tag_url(@pet)
    assert_equal "Новое публичное сообщение", @pet_tag.reload.public_message
    assert_not @pet_tag.show_phone?
    assert_not @pet_tag.show_medical_notes?
    assert @pet_tag.notify_always?
  end

  test "should update pet tag notification channels" do
    assert_difference("PetTagNotificationChannel.count") do
      patch pet_pet_tag_url(@pet), params: {
        pet_tag: {
          safety_status: @pet_tag.safety_status,
          notification_channel_ids: [notification_channels(:email).id]
        }
      }
    end

    assert_redirected_to pet_pet_tag_url(@pet)
    assert_equal [notification_channels(:email)], @pet_tag.reload.notification_channels.to_a
  end

  test "should update lost mode fields" do
    patch pet_pet_tag_url(@pet), params: {
      pet_tag: {
        lost_mode_enabled: "1",
        safety_status: "lost",
        lost_message: "Питомец потерялся, напишите сразу.",
        last_seen_location: "Сквер у школы"
      }
    }

    assert_redirected_to pet_pet_tag_url(@pet)
    assert @pet_tag.reload.lost_mode_enabled?
    assert_equal "Питомец потерялся, напишите сразу.", @pet_tag.lost_message
    assert_equal "Сквер у школы", @pet_tag.last_seen_location
  end

  test "should mark safety statuses" do
    patch mark_found_pet_pet_tag_url(@pet), params: { found_message: "Питомца нашли" }
    assert_redirected_to pet_pet_tag_url(@pet)
    assert @pet_tag.reload.status_found?

    patch mark_reunited_pet_pet_tag_url(@pet)
    assert_redirected_to pet_pet_tag_url(@pet)
    assert @pet_tag.reload.status_reunited?
    assert_not @pet_tag.lost_mode_enabled?

    patch mark_lost_pet_pet_tag_url(@pet)
    assert_redirected_to pet_pet_tag_url(@pet)
    assert @pet_tag.reload.status_lost?
  end

  test "should filter scans" do
    get pet_pet_tag_url(@pet, scan_status: "found_reported")

    assert_response :success
    assert_select "select[name='scan_status'] option[value='found_reported'][selected]", count: 1
  end

  test "should rotate public token" do
    old_token = @pet_tag.public_token

    patch rotate_token_pet_pet_tag_url(@pet)

    assert_redirected_to pet_pet_tag_url(@pet)
    assert_not_equal old_token, @pet_tag.reload.public_token
    assert @pet_tag.token_rotated_at.present?
  end

  test "should download qr svg" do
    get qr_pet_pet_tag_url(@pet, format: :svg)

    assert_response :success
    assert_equal "image/svg+xml", response.media_type
  end

  test "should download qr png" do
    get qr_pet_pet_tag_url(@pet, format: :png)

    assert_response :success
    assert_equal "image/png", response.media_type
  end
end
