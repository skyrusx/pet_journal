require "test_helper"

class OauthProfileTest < ActiveSupport::TestCase
  test "serializes only normalized profile data needed between callback and registration" do
    profile = Oauth::Profile.new(
      provider: "vk",
      uid: "123",
      email: "owner@example.com",
      name: "Owner",
      phone: "+79990000000",
      avatar_url: "https://example.com/avatar.jpg"
    )

    restored = Oauth::Profile.from_session(profile.to_session)

    assert_equal profile.to_session, restored.to_session
  end
end
