require "test_helper"

class PagesControllerTest < ActionDispatch::IntegrationTest
  test "should get guest index" do
    get root_url

    assert_response :success
    assert_select ".guest-hero"
    assert_select "h1", text: /Здоровье, уход и безопасность/
  end

  test "should get signed in dashboard" do
    sign_in users(:one)

    get root_url

    assert_response :success
    assert_select ".home-dashboard"
    assert_select ".home-pet-card", minimum: 1
    assert_select ".dashboard-section", text: /Напоминания/
  end
end
