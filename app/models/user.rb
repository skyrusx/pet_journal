class User < ApplicationRecord
  AVATAR_CONTENT_TYPES = %w[image/jpeg image/png image/webp].freeze
  AVATAR_MAX_SIZE = 5.megabytes
  INTERFACE_TEXT_SIZES = %w[compact standard comfortable large].freeze

  has_one_attached :avatar

  has_many :pets, dependent: :destroy
  has_many :notification_channels, dependent: :destroy
  has_many :in_app_notifications, dependent: :destroy
  has_many :user_consents, dependent: :destroy
  has_many :pet_birthday_greetings, dependent: :destroy
  has_many :reminders, through: :pets

  attr_accessor :remove_avatar, :personal_data_consent

  validates :name, length: { maximum: 80 }, allow_blank: true
  validates :phone, length: { maximum: 32 }, allow_blank: true
  validates :interface_text_size, inclusion: { in: INTERFACE_TEXT_SIZES }
  validates :notifications_time_zone, inclusion: { in: ->(_) { ActiveSupport::TimeZone.all.map(&:name) } }
  validates :personal_data_consent,
            acceptance: { accept: "1", message: "необходимо для создания аккаунта" },
            if: :personal_data_consent_required?
  validate :acceptable_avatar

  after_create :record_personal_data_consent!, if: :personal_data_consent_required?

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

  def prepare_personal_data_consent!(value:, ip_address:, user_agent:)
    self.personal_data_consent = value
    @personal_data_consent_metadata = {
      ip_address: ip_address,
      user_agent: user_agent
    }
  end

  private

  def personal_data_consent_required?
    new_record? && Rails.configuration.x.legal.require_personal_data_consent
  end

  def record_personal_data_consent!
    metadata = @personal_data_consent_metadata || {}

    UserConsent.create!(
      user: self,
      consent_type: "personal_data_processing",
      document_version: Rails.configuration.x.legal.personal_data_consent_version,
      accepted_at: Time.current,
      ip_address: metadata[:ip_address],
      user_agent: metadata[:user_agent]
    )
  ensure
    @personal_data_consent_metadata = nil
  end

  def acceptable_avatar
    return unless avatar.attached?

    errors.add(:avatar, "должен быть изображением JPEG, PNG или WebP") unless AVATAR_CONTENT_TYPES.include?(avatar.blob.content_type)
    errors.add(:avatar, "не должен быть больше 5 МБ") if avatar.blob.byte_size > AVATAR_MAX_SIZE
  end
end
