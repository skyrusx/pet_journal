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
    assert_routing({ method: "get", path: "/register" }, controller: "users/registrations", action: "new")
    assert_routing({ method: "post", path: "/register" }, controller: "users/registrations", action: "create")
    assert_routing({ method: "get", path: "/account" }, controller: "users/registrations", action: "edit")
    assert_routing({ method: "patch", path: "/account" }, controller: "users/registrations", action: "update")
    assert_routing({ method: "put", path: "/account" }, controller: "users/registrations", action: "update")
    assert_routing({ method: "delete", path: "/account" }, controller: "users/registrations", action: "destroy")
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
          password_confirmation: "password123",
          personal_data_consent: "1"
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
    assert_redirected_to edit_user_registration_path

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
    assert_select "a.pj-dash-nav__item.active[href=?]", root_path, text: /Главная/

    get pets_path
    assert_select "a.pj-dash-nav__item.active[href=?]", pets_path, text: /Питомцы/

    get notification_channels_path
    assert_select "a.pj-dash-nav__item.active[href=?]", settings_path, text: /Настройки/

    get edit_user_registration_path
    assert_response :success
    assert_select "a.pj-dash-profile-popover__item[href=?]", edit_user_registration_path, text: /Профиль/
  end

  test "pet profile exposes quick section links and journal marks workspace navigation active" do
    sign_in @user

    get pet_path(@pet)
    assert_response :success
    assert_select ".pj-pet-quick-section" do
      assert_select "a.pj-pet-quick-card[href=?]", journal_overview_path(pet_id: @pet.id), text: /Журнал/
      assert_select "a.pj-pet-quick-card[href=?]", pet_reminders_path(@pet), text: /Напоминания/
      assert_select "a.pj-pet-quick-card[href=?]", pet_pet_documents_path(@pet), text: /Документы/
      assert_select "a.pj-pet-quick-card[href=?]", pet_pet_tag_path(@pet), text: /PetTag/
      assert_select "a.pj-pet-quick-card[href=?]", pet_profile_shares_path(@pet), text: /Доступ/
    end
    assert_select "a.pj-desktop-detail-action[href=?]", edit_pet_path(@pet), count: 1

    get pet_pet_events_path(@pet)
    assert_response :success
    assert_select "a.pj-dash-nav__item.active[href=?]", journal_overview_path, text: /Журнал/
  end
end
