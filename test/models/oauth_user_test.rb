require "test_helper"

class OauthUserTest < ActiveSupport::TestCase
  test "changing generated oauth password marks password as configured" do
    user = users(:one)
    user.update_column(:password_configured, false)

    user.update!(password: "new-password-123", password_confirmation: "new-password-123")

    assert user.reload.password_configured?
  end
end
