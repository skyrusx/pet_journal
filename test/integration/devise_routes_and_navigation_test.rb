require "test_helper"

class DeviseRoutesAndNavigationTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @pet = pets(:one)
  end

  test "custom devise named helpers generate approved urls" do
    assert_equal "/login", new_user_session_path
    assert_equal "/login", user_session_path
    assert_equal "/logout", destroy_user_session_path
    assert_equal "/register", new_user_registration_path
    assert_equal "/register", user_registration_path
    assert_equal "/account", edit_user_registration_path
    assert_equal "/password/new", new_user_password_path
    assert_equal "/password/edit", edit_user_password_path
    assert_equal "/password", user_password_path
  end

  test "custom devise routes point to expected controllers" do
    assert_routing({ method: "get", path: "/login" }, controller: "devise/sessions", action: "new")
    assert_routing({ method: "post", path: "/login" }, controller: "devise/sessions", action: "create")
    assert_routing({ method: "delete", path: "/logout" }, controller: "devise/sessions", action: "destroy")
    assert_routing({ method: "get", path: "/register" }, controller: "devise/registrations", action: "new")
    assert_routing({ method: "post", path: "/register" }, controller: "devise/registrations", action: "create")
    assert_routing({ method: "get", path: "/account" }, controller: "devise/registrations", action: "edit")
    assert_routing({ method: "patch", path: "/account" }, controller: "devise/registrations", action: "update")
    assert_routing({ method: "put", path: "/account" }, controller: "devise/registrations", action: "update")
    assert_routing({ method: "delete", path: "/account" }, controller: "devise/registrations", action: "destroy")
    assert_routing({ method: "get", path: "/password/new" }, controller: "devise/passwords", action: "new")
    assert_routing({ method: "post", path: "/password" }, controller: "devise/passwords", action: "create")
    assert_routing({ method: "get", path: "/password/edit" }, controller: "devise/passwords", action: "edit")
    assert_routing({ method: "patch", path: "/password" }, controller: "devise/passwords", action: "update")
    assert_routing({ method: "put", path: "/password" }, controller: "devise/passwords", action: "update")
  end

  test "public devise forms open and protected account requires authentication" do
    get new_user_session_path
    assert_response :success
    assert_select "form[action=?]", user_session_path

    get new_user_registration_path
    assert_response :success
    assert_select "form[action=?]", user_registration_path

    get new_user_password_path
    assert_response :success
    assert_select "form"

    get edit_user_registration_path
    assert_redirected_to new_user_session_path
  end

  test "login logout registration account and recovery flows use custom urls" do
    post user_session_path, params: { user: { email: @user.email, password: "password123" } }
    assert_redirected_to root_path

    delete destroy_user_session_path
    assert_redirected_to root_path

    assert_difference("User.count", 1) do
      post user_registration_path, params: {
        user: {
          email: "route-user@example.test",
          password: "password123",
          password_confirmation: "password123"
        }
      }
    end
    assert_redirected_to root_path

    sign_in @user
    get edit_user_registration_path
    assert_response :success

    patch edit_user_registration_path, params: {
      user: {
        email: @user.email,
        password: "",
        password_confirmation: "",
        current_password: "password123"
      }
    }
    assert_redirected_to root_path

    disposable = User.create!(email: "delete-account@example.test", password: "password123", password_confirmation: "password123")
    sign_in disposable
    assert_difference("User.count", -1) do
      delete edit_user_registration_path, params: { user: { current_password: "password123" } }
    end

    assert_emails 1 do
      post user_password_path, params: { user: { email: @user.email } }
    end

    token = @user.send_reset_password_instructions
    get edit_user_password_path(reset_password_token: token)
    assert_response :success

    patch user_password_path, params: {
      user: {
        reset_password_token: token,
        password: "password456",
        password_confirmation: "password456"
      }
    }
    assert_redirected_to root_path
  end

  test "own templates do not link to skipped devise urls" do
    template_text = Dir[Rails.root.join("app/views/**/*.erb")].map { |path| File.read(path) }.join("\n")

    assert_no_match %r{href=["']/users/sign_in}, template_text
    assert_no_match %r{href=["']/users/sign_up}, template_text
    assert_no_match %r{href=["']/users/password}, template_text
    assert_no_match %r{action=["']/users/sign_in}, template_text
    assert_no_match %r{action=["']/users/sign_up}, template_text
  end

  test "global navigation marks active section" do
    sign_in @user

    get root_path
    assert_select "a.app-nav-link.active[href=?]", root_path, text: "Рабочий стол"

    get pets_path
    assert_select "a.app-nav-link.active[href=?]", pets_path, text: "Мои питомцы"

    get notification_channels_path
    assert_select "a.app-nav-link.active[href=?]", notification_channels_path, text: "Уведомления"

    get edit_user_registration_path
    assert_select "a.app-nav-link[href=?]", edit_user_registration_path, count: 0
    assert_select "details.app-user-menu summary.active"
    assert_select "a.app-user-dropdown-link.active[href=?]", edit_user_registration_path, text: "Настройки аккаунта"
  end

  test "pet tabs expose expected links and active tab follows controller" do
    sign_in @user

    get pet_path(@pet)
    assert_select "nav.pet-tabs" do
      assert_select "a[href=?]", pet_path(@pet), text: "Обзор"
      assert_select "a[href=?]", pet_pet_events_path(@pet), text: "Журнал"
      assert_select "a[href=?]", pet_reminders_path(@pet), text: "Напоминания"
      assert_select "a[href=?]", pet_pet_documents_path(@pet), text: "Документы"
      assert_select "a[href=?]", pet_pet_tag_path(@pet), text: "Жетон"
      assert_select "a[href=?]", pet_profile_shares_path(@pet), text: "Доступ"
      assert_select "a[href=?]", edit_pet_path(@pet), text: "Данные"
      assert_select "a.pet-tab.active[href=?]", pet_path(@pet), text: "Обзор"
    end

    get pet_pet_events_path(@pet)
    assert_select "a.pet-tab.active[href=?]", pet_pet_events_path(@pet), text: "Журнал"
  end
end
