require "test_helper"

class PersonalDataRegistrationTest < ActionDispatch::IntegrationTest
  test "registration page exposes separate consent and policy links" do
    get new_user_registration_path

    assert_response :success
    assert_select "input[name='user[personal_data_consent]'][type='checkbox'][required]", count: 1
    assert_select "a[href=?]", personal_data_consent_path
    assert_select "a[href=?]", privacy_path
  end

  test "registration is rejected without personal data consent" do
    assert_no_difference(["User.count", "UserConsent.count"]) do
      post user_registration_path, params: {
        user: {
          name: "Тестовый пользователь",
          email: "without-consent@example.test",
          password: "password123",
          password_confirmation: "password123",
          personal_data_consent: "0"
        }
      }
    end

    assert_response :unprocessable_entity
    assert_select ".flash-toast.alert", minimum: 1
  end

  test "registration atomically records consent version and request metadata" do
    assert_difference("User.count", 1) do
      assert_difference("UserConsent.count", 1) do
        post user_registration_path,
             params: {
               user: {
                 name: "Тестовый пользователь",
                 email: "with-consent@example.test",
                 password: "password123",
                 password_confirmation: "password123",
                 personal_data_consent: "1"
               }
             },
             headers: { "User-Agent" => "PetJournal test browser" }
      end
    end

    user = User.find_by!(email: "with-consent@example.test")
    consent = user.user_consents.active.find_by!(consent_type: UserConsent::PERSONAL_DATA)

    assert_equal LegalDocuments.version(:personal_data_consent), consent.document_version
    assert_equal "registration", consent.source
    assert_equal "PetJournal test browser", consent.user_agent
    assert consent.accepted_at.present?
    assert_equal LegalDocuments.version(:privacy_policy), consent.metadata.fetch("privacy_policy_version")
    assert_redirected_to root_path
  end
end
