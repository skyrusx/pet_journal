require "test_helper"

class BirthdayGreetingDispatchJobTest < ActiveJob::TestCase
  include ActionMailer::TestHelper

  setup do
    ActionMailer::Base.deliveries.clear
  end

  test "sends one email after noon when greeting was not shown" do
    user = users(:one)
    user.update!(notifications_time_zone: "UTC")
    pet = pets(:one)
    pet.update!(name: "Тор", sex: 0, birth_date: Date.new(2018, 9, 2))
    reference_time = Time.utc(2026, 9, 2, 13, 0, 0)

    assert_emails 1 do
      BirthdayGreetingDispatchJob.perform_now(reference_time)
    end

    greeting = PetBirthdayGreeting.find_by!(user: user, greeting_date: Date.new(2026, 9, 2))
    assert greeting.email_sent_at.present?

    assert_emails 0 do
      BirthdayGreetingDispatchJob.perform_now(reference_time + 15.minutes)
    end
  end

  test "does not email after greeting was shown" do
    user = users(:one)
    user.update!(notifications_time_zone: "UTC")
    pets(:one).update!(birth_date: Date.new(2018, 9, 2))
    PetBirthdayGreeting.create!(
      user: user,
      greeting_date: Date.new(2026, 9, 2),
      shown_at: Time.utc(2026, 9, 2, 9, 0, 0)
    )

    assert_emails 0 do
      BirthdayGreetingDispatchJob.perform_now(Time.utc(2026, 9, 2, 13, 0, 0))
    end
  end

  test "does not email before noon in user time zone" do
    user = users(:one)
    user.update!(notifications_time_zone: "UTC")
    pets(:one).update!(birth_date: Date.new(2018, 9, 2))

    assert_emails 0 do
      BirthdayGreetingDispatchJob.perform_now(Time.utc(2026, 9, 2, 9, 0, 0))
    end

    assert_nil PetBirthdayGreeting.find_by(user: user, greeting_date: Date.new(2026, 9, 2))
  end
end
