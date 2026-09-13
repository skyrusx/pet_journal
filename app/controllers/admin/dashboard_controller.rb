class Admin::DashboardController < Admin::ApplicationController
  def index
    period = 7.days.ago.beginning_of_day..Time.current

    @activity = {
      users: User.where(created_at: period).count,
      pets: Pet.where(created_at: period).count,
      events: PetEvent.where(created_at: period).count,
      reminders: Reminder.where(created_at: period).count
    }

    @attention = {
      failed_deliveries: NotificationDelivery.status_failed.where(created_at: period).count,
      retry_deliveries: NotificationDelivery.status_pending.where("attempts_count > 0").count,
      lost_pets: PetTag.status_lost.count
    }

    @usage = {
      registered: User.count,
      with_pet: User.joins(:pets).distinct.count,
      with_event: User.joins(pets: :pet_events).distinct.count,
      with_reminder: User.joins(pets: :reminders).distinct.count,
      with_pettag: User.joins(pets: :pet_tag).distinct.count
    }

    @registration_series = registration_series
    @registration_max = [@registration_series.map { |item| item[:count] }.max.to_i, 1].max
    @recent_users = User.includes(:pets).order(created_at: :desc).limit(6)
  end

  private

  def registration_series
    start_date = 29.days.ago.to_date
    counts = User.where(created_at: start_date.beginning_of_day..Time.current)
                 .group("DATE(created_at)")
                 .count

    (start_date..Date.current).map do |date|
      { date: date, count: counts[date] || counts[date.to_s] || 0 }
    end
  end
end
