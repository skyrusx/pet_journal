require "test_helper"

class AdminEntryPointTest < ActionDispatch::IntegrationTest
  test "regular user does not see management entry point" do
    sign_in users(:one)

    get root_url

    assert_response :success
    assert_select "a[href=?]", admin_root_path, count: 0
  end

  test "admin sees management entry point on desktop and mobile" do
    admin = users(:one)
    admin.update!(admin: true)
    sign_in admin

    get root_url

    assert_response :success
    assert_select ".app-user-dropdown a[href=?]", admin_root_path, text: "Управление"
    assert_select "#mobile-more-sheet a[href=?]", admin_root_path, text: /Управление/
  end
end
