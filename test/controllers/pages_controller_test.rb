require "test_helper"

class PagesControllerTest < ActionDispatch::IntegrationTest
  test "should get guest index" do
    get root_url

    assert_response :success
    assert_select ".pj-landing"
    assert_select ".pj-hero h1", text: /Помните всё важное/
    assert_select ".pj-feature-grid article", count: 6
    assert_select "#pettag"
    assert_select "#faq"
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
