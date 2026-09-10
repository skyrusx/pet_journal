require "test_helper"
require "cgi"
require "uri"

class OauthControllerTest < ActionDispatch::IntegrationTest
  class FakeProvider
    attr_reader :profile

    def initialize(profile)
      @profile = profile
    end

    def authorization_url(state:, code_challenge:)
      "https://provider.example/authorize?#{URI.encode_www_form(state: state, challenge: code_challenge)}"
    end

    def fetch_profile(**)
      profile
    end
  end

  test "new oauth user completes consent before PetJournal account is created" do
    profile = Oauth::Profile.new(
      provider: "vk",
      uid: "vk-new-user",
      email: "oauth-new@example.com",
      name: "OAuth User",
      phone: "+79990000001"
    )

    with_fake_provider(profile) do
      start_oauth("vk")
      callback_oauth("vk")
      assert_redirected_to oauth_complete_path

      assert_difference(["User.count", "ExternalIdentity.count", "UserConsent.count"], 1) do
        post oauth_register_path, params: { personal_data_consent: "1" }
      end
    end

    user = User.find_by!(email: profile.email)
    identity = user.external_identities.find_by!(provider: "vk")
    consent = user.user_consents.find_by!(consent_type: UserConsent::PERSONAL_DATA)

    assert_equal profile.uid, identity.uid
    assert_equal profile.name, user.name
    assert_equal profile.phone, user.phone
    assert_not user.password_configured?
    assert_equal "oauth_registration", consent.source
    assert_equal "vk", consent.metadata["oauth_provider"]
  end

  test "matching email never auto-links an untrusted external identity" do
    user = users(:one)
    profile = Oauth::Profile.new(
      provider: "yandex",
      uid: "ya-same-email",
      email: user.email,
      name: "Someone"
    )

    with_fake_provider(profile) do
      start_oauth("yandex")
      assert_no_difference("ExternalIdentity.count") do
        callback_oauth("yandex")
      end
    end

    assert_redirected_to new_user_session_path
  end

  test "signed in user can explicitly link an external identity" do
    user = users(:one)
    sign_in user
    profile = Oauth::Profile.new(
      provider: "yandex",
      uid: "ya-linked",
      email: "other@example.com",
      name: "Provider Name",
      phone: "+79990000002"
    )

    with_fake_provider(profile) do
      start_oauth("yandex", purpose: "link")
      assert_difference("ExternalIdentity.count", 1) do
        callback_oauth("yandex")
      end
    end

    assert_equal "ya-linked", user.reload.external_identities.find_by!(provider: "yandex").uid
  end

  test "disconnect requires fresh provider authentication and removes only the confirmed identity" do
    user = users(:one)
    identity = ExternalIdentity.create!(
      user: user,
      provider: "vk",
      uid: "vk-connected",
      connected_at: Time.current
    )
    sign_in user
    profile = Oauth::Profile.new(provider: "vk", uid: identity.uid, email: user.email)

    with_fake_provider(profile) do
      start_oauth("vk", purpose: "disconnect")
      assert_difference("ExternalIdentity.count", -1) do
        callback_oauth("vk")
      end
    end

    assert_redirected_to edit_user_registration_path
  end

  test "oauth-only user cannot disconnect the final login method" do
    user = users(:one)
    user.update_column(:password_configured, false)
    ExternalIdentity.create!(user: user, provider: "vk", uid: "vk-last", connected_at: Time.current)
    sign_in user

    assert_no_difference("ExternalIdentity.count") do
      get oauth_start_path(provider: "vk", purpose: "disconnect")
    end

    assert_redirected_to edit_user_registration_path
  end

  private

  def with_fake_provider(profile, &block)
    fake = FakeProvider.new(profile)
    Oauth::Provider.stub(:build, fake, &block)
  end

  def start_oauth(provider, purpose: nil)
    get oauth_start_path(provider: provider, purpose: purpose)
    assert_response :redirect
    @oauth_state = CGI.parse(URI(response.location).query).fetch("state").first
  end

  def callback_oauth(provider)
    params = { code: "test-code", state: @oauth_state }
    params[:device_id] = "test-device" if provider == "vk"
    get oauth_callback_path(provider: provider), params: params
  end
end
