require "test_helper"

class SecurityProtectionTest < ActionDispatch::IntegrationTest
  setup do
    @rack_attack_enabled = Rack::Attack.enabled
    @rack_attack_store = Rack::Attack.cache.store

    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
    Rack::Attack.enabled = true
    Rack::Attack.reset!
  end

  teardown do
    Rack::Attack.reset!
    Rack::Attack.cache.store = @rack_attack_store
    Rack::Attack.enabled = @rack_attack_enabled
  end

  test "register form includes honeypot and signed timing token" do
    get new_user_registration_path

    assert_response :success
    assert_select "input[name='contact_website']", count: 1
    assert_select "input[name='security_form_token'][type='hidden']", count: 1
  end

  test "login and password reset forms include anti-spam fields" do
    get new_user_session_path

    assert_response :success
    assert_select "input[name='contact_website']", count: 1
    assert_select "input[name='security_form_token'][type='hidden']", count: 1

    get new_user_password_path

    assert_response :success
    assert_select "input[name='contact_website']", count: 1
    assert_select "input[name='security_form_token'][type='hidden']", count: 1
  end

  test "registration honeypot rejects obvious bot submission" do
    assert_no_difference("User.count") do
      post user_registration_path, params: {
        contact_website: "https://spam.example",
        user: {
          name: "Spam Bot",
          email: "spam-bot@example.test",
          password: "password123",
          password_confirmation: "password123",
          personal_data_consent: "1"
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "login honeypot rejects obvious bot submission" do
    post user_session_path, params: {
      contact_website: "https://spam.example",
      user: {
        email: users(:one).email,
        password: "password123"
      }
    }

    assert_response :unprocessable_entity
  end

  test "registration rate limit returns friendly 429 response" do
    5.times do |index|
      post user_registration_path, params: {
        user: {
          email: "invalid-#{index}@example.test",
          password: "short"
        }
      }
      assert_response :unprocessable_entity
    end

    post user_registration_path, params: {
      user: {
        email: "invalid-last@example.test",
        password: "short"
      }
    }

    assert_response :too_many_requests
    assert response.headers["Retry-After"].present?
    assert_includes response.body, "Слишком много попыток"
  end

  test "password reset is limited by normalized email" do
    3.times do
      post user_password_path, params: { user: { email: "missing@example.test" } }
      assert_response :redirect
    end

    post user_password_path, params: { user: { email: " MISSING@example.test " } }

    assert_response :too_many_requests
  end

  test "Devise password recovery uses paranoid responses" do
    assert Devise.paranoid
  end

  test "PetTag finder form includes anti-spam fields" do
    pet_tag = pet_tags(:one)

    get public_pet_tag_path(pet_tag.public_token)

    assert_response :success
    assert_select "input[name='contact_website']", count: 1
    assert_select "input[name='security_form_token'][type='hidden']", count: 1
  end

  test "PetTag finder honeypot rejects submission before storing finder data" do
    pet_tag = pet_tags(:one)
    get public_pet_tag_path(pet_tag.public_token)
    scan = pet_tag.pet_tag_scans.order(:created_at).last

    assert_no_changes -> { scan.reload.finder_message } do
      post public_pet_tag_location_path(pet_tag.public_token), params: {
        scan_token: scan.public_token,
        contact_website: "https://spam.example",
        finder_personal_data_consent: "1",
        finder_message: "Spam"
      }
    end

    assert_response :unprocessable_entity
  end

  test "all public security throttles are registered" do
    expected = %w[
      security/register/ip
      security/login/ip
      security/login/email
      security/password_reset/ip
      security/password_reset/email
      security/public_pet_tag/show/ip
      security/public_pet_tag/location/ip
      security/public_pet_tag/location/token
      security/public_profile_share/show/ip
    ]

    expected.each do |name|
      assert_includes Rack::Attack.throttles.keys, name
    end
  end
end
