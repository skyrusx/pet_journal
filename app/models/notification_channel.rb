class NotificationChannel < ApplicationRecord
  belongs_to :user
  has_many :notification_deliveries, dependent: :destroy

  enum :channel_type, { email: 0, telegram: 1, vk: 2, web_push: 3 }, prefix: :channel

  validates :channel_type, :name, presence: true
  validates :address, presence: true, unless: :channel_web_push?
  validate :web_push_settings_present, if: :channel_web_push?

  scope :enabled, -> { where(enabled: true) }

  def channel_type_label
    I18n.t("notification_channels.types.#{channel_type}")
  end

  def verified?
    verified_at.present?
  end

  private

  def web_push_settings_present
    return if settings["endpoint"].present? && settings["p256dh"].present? && settings["auth"].present?

    errors.add(:settings, :blank)
  end
end
