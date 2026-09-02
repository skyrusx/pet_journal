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
    @personal_data_consent_context = {
      ip_address: ip_address,
      user_agent: user_agent.to_s.truncate(500)
    }
  end

  private

  def personal_data_consent_required?
    @personal_data_consent_context.present?
  end

  def record_personal_data_consent!
    user_consents.create!(
      consent_type: UserConsent::PERSONAL_DATA,
      document_version: LegalDocuments.version(:personal_data_consent),
      accepted_at: Time.current,
      source: "registration",
      ip_address: @personal_data_consent_context[:ip_address],
      user_agent: @personal_data_consent_context[:user_agent],
      metadata: {
        "privacy_policy_version" => LegalDocuments.version(:privacy_policy)
      }
    )
  end

  def acceptable_avatar
    return unless avatar.attached?

    unless AVATAR_CONTENT_TYPES.include?(avatar.blob.content_type)
      errors.add(:avatar, "должен быть JPG, PNG или WebP")
    end

    errors.add(:avatar, "должен быть меньше 5 МБ") if avatar.blob.byte_size > AVATAR_MAX_SIZE
  end
end
