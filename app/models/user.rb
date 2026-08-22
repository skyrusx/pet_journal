class User < ApplicationRecord
  AVATAR_CONTENT_TYPES = %w[image/jpeg image/png image/webp].freeze
  AVATAR_MAX_SIZE = 5.megabytes
  INTERFACE_TEXT_SIZES = %w[compact standard comfortable large].freeze

  has_one_attached :avatar

  has_many :pets, dependent: :destroy
  has_many :notification_channels, dependent: :destroy
  has_many :reminders, through: :pets

  attr_accessor :remove_avatar

  validates :name, length: { maximum: 80 }, allow_blank: true
  validates :phone, length: { maximum: 32 }, allow_blank: true
  validates :interface_text_size, inclusion: { in: INTERFACE_TEXT_SIZES }
  validates :notifications_time_zone, inclusion: { in: ->(_) { ActiveSupport::TimeZone.all.map(&:name) } }
  validate :acceptable_avatar

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  def notifications_time_zone_name
    notifications_time_zone.presence || Time.zone.name
  end

  def interface_text_size_name
    interface_text_size.presence_in(INTERFACE_TEXT_SIZES) || "standard"
  end

  def interface_text_size_css_class
    "pj-text-size-#{interface_text_size_name}"
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

  private

  def acceptable_avatar
    return unless avatar.attached?

    unless AVATAR_CONTENT_TYPES.include?(avatar.blob.content_type)
      errors.add(:avatar, "должен быть JPG, PNG или WebP")
    end

    errors.add(:avatar, "должен быть меньше 5 МБ") if avatar.blob.byte_size > AVATAR_MAX_SIZE
  end
end
