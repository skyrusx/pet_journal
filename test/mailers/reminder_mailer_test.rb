require "test_helper"

class ReminderMailerTest < ActionMailer::TestCase
  test "renders branded reminder email with direct link and inline logo" do
    reminder = reminders(:one)
    channel = notification_channels(:email)

    mail = ReminderMailer.due_reminder(reminder, channel)

    assert_equal [channel.address], mail.to
    assert_equal "#{reminder.pet.name}: #{reminder.title} — PetJournal", mail.subject

    logo = mail.attachments.find { |attachment| attachment.filename == "petjournal-logo.png" }
    assert logo.present?
    assert logo.inline?

    html = mail.html_part.body.decoded
    text = mail.text_part.body.decoded
    reminder_url = Rails.application.routes.url_helpers.pet_reminder_url(
      reminder.pet,
      reminder,
      host: "www.example.com"
    )

    assert_includes html, reminder.title
    assert_includes html, reminder.pet.name
    assert_includes html, "Открыть напоминание"
    assert_includes html, reminder_url
    assert_includes text, reminder_url
    assert_includes text, reminder.note
  end
end
