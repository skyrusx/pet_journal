require "test_helper"

class BirthdayGreetingFlowTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @user.update!(notifications_time_zone: "UTC")
    sign_in @user
  end

  test "does not show greeting on an ordinary day" do
    travel_to Time.utc(2026, 9, 3, 9, 0, 0) do
      get root_url

      assert_response :success
      assert_select "[data-birthday-greeting]", count: 0
    end
  end

  test "shows approved single-pet greeting once" do
    pets(:one).update!(name: "Тор", sex: 0, birth_date: Date.new(2018, 9, 2))

    travel_to Time.utc(2026, 9, 2, 9, 0, 0) do
      get root_url

      assert_response :success
      assert_select "[data-birthday-greeting]", count: 1
      assert_select ".pj-birthday-greeting__title", text: "🎉 Сегодня день рождения Тора!"
      assert_select ".pj-birthday-greeting__text", text: /Исполняется 8 лет.*угостить вкусняшкой 🐾/
      assert PetBirthdayGreeting.find_by!(user: @user, greeting_date: Date.current).shown_at.present?

      get pets_url

      assert_response :success
      assert_select "[data-birthday-greeting]", count: 0
    end
  end

  test "combines two birthday pets into one greeting" do
    pets(:one).update!(name: "Тор", sex: 0, birth_date: Date.new(2018, 9, 2))
    @user.pets.create!(name: "Локи", sex: 0, birth_date: Date.new(2021, 9, 2))

    travel_to Time.utc(2026, 9, 2, 9, 0, 0) do
      get root_url

      assert_response :success
      assert_select "[data-birthday-greeting]", count: 1
      assert_select ".pj-birthday-greeting__title", text: "🎉 Сегодня день рождения у Тора и Локи!"
      assert_select ".pj-birthday-greeting__avatar", count: 2
    end
  end

  test "still shows greeting after email was sent earlier" do
    pets(:one).update!(name: "Тор", sex: 0, birth_date: Date.new(2018, 9, 2))
    PetBirthdayGreeting.create!(
      user: @user,
      greeting_date: Date.new(2026, 9, 2),
      email_sent_at: Time.utc(2026, 9, 2, 12, 5, 0)
    )

    travel_to Time.utc(2026, 9, 2, 14, 0, 0) do
      get pets_url

      assert_response :success
      assert_select "[data-birthday-greeting]", count: 1
      assert PetBirthdayGreeting.find_by!(user: @user, greeting_date: Date.current).shown_at.present?
    end
  end
end
