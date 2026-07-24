require "test_helper"

class PetDocumentTest < ActiveSupport::TestCase
  test "validates expiration is not before issue date" do
    document = pets(:one).pet_documents.new(
      title: "Справка",
      document_type: :certificate,
      issued_on: Date.current,
      expires_on: 1.day.ago
    )

    assert_not document.valid?
    assert_includes document.errors[:expires_on], "не может быть раньше даты выдачи"
  end

  test "syncs journal event" do
    document = pet_documents(:passport)

    assert_difference("PetEvent.count") do
      document.sync_journal_event!
    end

    assert_equal "document", document.reload.pet_event.event_type
    assert_equal document.title, document.pet_event.title
  end

  test "syncs expiry reminder" do
    document = pet_documents(:expiring)

    assert_difference("Reminder.count") do
      document.sync_expiry_reminder!
    end

    assert_equal document.reminder, Reminder.order(:created_at).last
    assert_equal document.expires_on - document.expiry_reminder_days.days, document.reminder.remind_at.to_date
  end

  test "removes expiry reminder when expiration is removed" do
    document = pet_documents(:expiring)
    document.sync_expiry_reminder!
    reminder = document.reminder

    assert_difference("Reminder.count", -1) do
      document.update!(expires_on: nil)
      document.sync_expiry_reminder!
    end

    assert_nil document.reload.reminder
    assert_raises(ActiveRecord::RecordNotFound) { reminder.reload }
  end
end
