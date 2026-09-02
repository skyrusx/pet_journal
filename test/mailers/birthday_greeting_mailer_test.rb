require "test_helper"

class BirthdayGreetingMailerTest < ActionMailer::TestCase
  test "birthday greeting email contains approved copy" do
    user = users(:one)
    pet = pets(:one)
    pet.assign_attributes(name: "Тор", sex: 0, birth_date: Date.new(2018, 9, 2))

    email = BirthdayGreetingMailer.greeting(user, [pet], Date.new(2026, 9, 2))

    assert_equal [user.email], email.to
    assert_match "Сегодня день рождения Тора!", email.subject
    assert_match "Исполняется 8 лет", email.text_part.body.to_s
  end
end
