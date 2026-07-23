class User < ApplicationRecord
  has_many :pets, dependent: :destroy
  has_many :notification_channels, dependent: :destroy
  has_many :reminders, through: :pets
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  def notifications_time_zone_name
    notifications_time_zone.presence || Time.zone.name
  end

  def quiet_hours_now?(time = Time.current)
    return false unless notifications_quiet_hours_enabled?

    zoned_time = time.in_time_zone(notifications_time_zone_name)
    current_minutes = zoned_time.hour * 60 + zoned_time.min
    start_minutes = notifications_quiet_hours_start.hour * 60 + notifications_quiet_hours_start.min
    end_minutes = notifications_quiet_hours_end.hour * 60 + notifications_quiet_hours_end.min

    if start_minutes < end_minutes
      current_minutes >= start_minutes && current_minutes < end_minutes
    else
      current_minutes >= start_minutes || current_minutes < end_minutes
    end
  end
end
