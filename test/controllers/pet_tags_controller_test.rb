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

  test "should create pet tag without enabling public phone from ordinary params" do
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

  test "should get edit and offer separate phone publication consent" do
    @pet_tag.update_columns(show_phone: false)

    get edit_pet_pet_tag_url(@pet)

    assert_response :success
    assert_select "a[href=?]", phone_consent_pet_pet_tag_path(@pet), text: /Разрешить публикацию/
    assert_select ".pj-pettag-token-management", text: /Телефон скрыт/
  end

  test "ordinary update cannot enable public phone" do
    @pet_tag.update_columns(show_phone: false)

    patch pet_pet_tag_url(@pet), params: {
      pet_tag: {
        public_message: "Новое публичное сообщение",
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

  test "phone consent page identifies exact phone resource and separate consent" do
    get phone_consent_pet_pet_tag_url(@pet)

    assert_response :success
    assert_select "input[name='subject_full_name'][required]", count: 1
    assert_select "input[name='phone_distribution_consent'][type='checkbox'][required]", count: 1
    assert_select "a[href=?]", pet_tag_phone_distribution_consent_path
    assert_match @pet_tag.contact_phone, response.body
    assert_match @pet_tag.tag_code, response.body
  end

  test "does not publish phone without separate consent" do
    @pet_tag.update_columns(show_phone: false)

    assert_no_difference("UserConsent.count") do
      post publish_phone_pet_pet_tag_url(@pet), params: {
        subject_full_name: "Иванов Иван Иванович"
      }
    end

    assert_response :unprocessable_entity
    assert_not @pet_tag.reload.show_phone?
  end

  test "publishes phone only after recording scoped distribution consent" do
    @pet_tag.update_columns(show_phone: false)

    assert_difference("UserConsent.count", 1) do
      post publish_phone_pet_pet_tag_url(@pet), params: {
        subject_full_name: "Иванов Иван Иванович",
        phone_distribution_consent: "1"
      }
    end

    assert_redirected_to edit_pet_pet_tag_url(@pet)
    assert @pet_tag.reload.show_phone?
    assert @pet_tag.phone_publication_allowed?

    consent = @pet_tag.active_phone_distribution_consent
    assert_equal @user, consent.user
    assert_equal @pet_tag, consent.consentable
    assert_equal UserConsent::PET_TAG_PHONE_DISTRIBUTION, consent.consent_type
    assert_equal LegalDocuments.version(:pet_tag_phone_distribution_consent), consent.document_version
    assert_equal @pet_tag.contact_phone, consent.metadata["phone"]
    assert_equal "Иванов Иван Иванович", consent.metadata["subject_full_name"]
    assert_equal @user.email, consent.metadata["subject_contact"]
    assert consent.accepted_at.present?
  end

  test "changing phone revokes distribution consent and hides phone" do
    @pet_tag.update_columns(show_phone: false)
    post publish_phone_pet_pet_tag_url(@pet), params: {
      subject_full_name: "Иванов Иван Иванович",
      phone_distribution_consent: "1"
    }
    consent = @pet_tag.reload.active_phone_distribution_consent

    patch pet_pet_tag_url(@pet), params: { pet_tag: { contact_phone: "+79990000077" } }

    assert_redirected_to pet_pet_tag_url(@pet)
    assert_not @pet_tag.reload.show_phone?
    assert_nil @pet_tag.active_phone_distribution_consent
    assert consent.reload.revoked_at.present?
  end

  test "revoking phone publication hides phone and records revocation" do
    @pet_tag.update_columns(show_phone: false)
    post publish_phone_pet_pet_tag_url(@pet), params: {
      subject_full_name: "Иванов Иван Иванович",
      phone_distribution_consent: "1"
    }
    consent = @pet_tag.reload.active_phone_distribution_consent

    delete revoke_phone_pet_pet_tag_url(@pet)

    assert_redirected_to edit_pet_pet_tag_url(@pet)
    assert_not @pet_tag.reload.show_phone?
    assert consent.reload.revoked_at.present?
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
