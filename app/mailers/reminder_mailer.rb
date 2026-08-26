class ReminderMailer < ApplicationMailer
  LOGO_PATH = Rails.root.join("app/assets/images/petjournal/logo-horizontal.png").freeze

  def due_reminder(reminder, channel)
    @reminder = reminder
    @pet = reminder.pet
    @channel = channel
    @scheduled_at = (reminder.next_run_at || reminder.remind_at).in_time_zone(@pet.user.notifications_time_zone_name)
    @reminder_url = pet_reminder_url(@pet, @reminder)

    attachments.inline["petjournal-logo.png"] = File.binread(LOGO_PATH) if LOGO_PATH.file?

    mail(
      to: channel.address,
      subject: "#{@pet.name}: #{@reminder.title} — PetJournal"
    )
  end
end
