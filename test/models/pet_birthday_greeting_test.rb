require "test_helper"

class PetBirthdayGreetingTest < ActiveSupport::TestCase
  test "claim_for_display marks greeting only once" do
    greeting = PetBirthdayGreeting.create!(user: users(:one), greeting_date: Date.new(2026, 9, 2))

    assert greeting.claim_for_display!
    assert greeting.reload.shown_at.present?
    assert_not greeting.claim_for_display!
  end
end
