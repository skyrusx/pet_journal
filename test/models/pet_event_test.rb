require "test_helper"

class PetEventTest < ActiveSupport::TestCase
  test "structured summary uses typed fields" do
    event = pet_events(:one)

    assert_equal "Nobivac", event.summary
    assert event.structured?
  end

  test "validates valid until after event date" do
    event = pets(:one).pet_events.new(event_type: :vaccination, event_date: Date.current, valid_until: 1.day.ago)

    assert_not event.valid?
    assert_includes event.errors[:valid_until], "не может быть раньше даты события"
  end

  test "illness requires severity" do
    event = pets(:one).pet_events.new(event_type: :illness, event_date: Date.current, symptoms: "Кашель")

    assert_not event.valid?
    assert_includes event.errors[:severity], "не может быть пустым"
  end
end
