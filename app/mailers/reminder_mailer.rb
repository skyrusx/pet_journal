class ReminderMailer < ApplicationMailer
  def due_reminder(reminder, channel)
    @reminder = reminder
    @pet = reminder.pet
    @channel = channel

    mail(to: channel.address, subject: "Напоминание PetJournal: #{reminder.title}")
  end
end
