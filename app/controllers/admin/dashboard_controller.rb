class Admin::DashboardController < Admin::ApplicationController
  def index
    period = 7.days.ago.beginning_of_day..Time.current
    users = User.user
    pets = Pet.where(user_id: users.select(:id))
    pet_ids = pets.select(:id)
    events = PetEvent.where(pet_id: pet_ids)
    reminders = Reminder.where(pet_id: pet_ids)
    tags = PetTag.where(pet_id: pet_ids)
    deliveries = NotificationDelivery.where(reminder_id: reminders.select(:id))

    @activity = {
      users: users.where(created_at: period).count,
      pets: pets.where(created_at: period).count,
      events: events.where(created_at: period).count,
      reminders: reminders.where(created_at: period).count
    }

    @attention = {
      failed_deliveries: deliveries.status_failed.where(created_at: period).count,
      retry_deliveries: deliveries.status_pending.where("attempts_count > 0").count,
      lost_pets: tags.status_lost.count
    }

    @usage = {
      registered: users.count,
      with_pet: users.joins(:pets).distinct.count,
      with_event: users.joins(pets: :pet_events).distinct.count,
      with_reminder: users.joins(pets: :reminders).distinct.count,
      with_pettag: users.joins(pets: :pet_tag).distinct.count
    }

    @registration_series = registration_series(users)
    @registration_max = [@registration_series.map { |item| item[:count] }.max.to_i, 1].max
    @recent_users = users.includes(:pets).order(created_at: :desc).limit(6)
  end

  private

  def registration_series(users)
    start_date = 29.days.ago.to_date
    counts = users.where(created_at: start_date.beginning_of_day..Time.current)
                  .group("DATE(created_at)")
                  .count

    (start_date..Date.current).map do |date|
      { date: date, count: counts[date] || counts[date.to_s] || 0 }
    end
  end
end
