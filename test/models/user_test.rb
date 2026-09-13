require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "new users use the user role by default" do
    user = User.new(email: "new@example.com", password: "password123")

    assert user.user?
    assert_not user.admin?
  end

  test "admin role exposes admin predicate" do
    assert users(:admin).admin?
  end
end
