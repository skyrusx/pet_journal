require "test_helper"

class PagesControllerTest < ActionDispatch::IntegrationTest
  test "should get new design on guest index" do
    get root_url

    assert_response :success
    assert_select ".pj-new-design"
    assert_select ".pj-nd-hero h1", text: /Вся забота.*о питомце.*в одном месте/m
    assert_select 'meta[name="description"]', count: 1
    assert_select 'meta[name="robots"][content*="noindex"]', count: 0
    assert_select 'link[rel="canonical"][href=?]', root_url
  end

  test "old new design preview should redirect to main page" do
    get new_design_url

    assert_response :moved_permanently
    assert_redirected_to root_url
  end

  test "should get signed in dashboard" do
    sign_in users(:one)

    get root_url

    assert_response :success
    assert_select ".pj-dash"
    assert_select ".pj-dash-pet-card", minimum: 1
    assert_select "a.pj-dash-nav__item.active[href=?]", root_path, text: /Главная/
  end
end
