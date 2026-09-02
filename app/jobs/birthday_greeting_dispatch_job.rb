class BirthdayGreetingDispatchJob < ApplicationJob
  queue_as :default

  DELIVERY_HOUR = 12

  def perform(reference_time = Time.current)
    User.find_each do |user|
      local_time = reference_time.in_time_zone(user.notifications_time_zone_name)
      next if local_time.hour < DELIVERY_HOUR

      dispatch_for(user, local_time.to_date)
    end
  end

  private

  def dispatch_for(user, date)
    pets = user.pets.birthday_on(date).order(:created_at).to_a
    return if pets.empty?

    greeting = PetBirthdayGreeting.create_or_find_by!(user: user, greeting_date: date)

    greeting.with_lock do
      return if greeting.shown_at.present? || greeting.email_sent_at.present?

      BirthdayGreetingMailer.greeting(user, pets, date).deliver_now
      greeting.update!(email_sent_at: Time.current)
    end
  end
end
