class NotificationChannel < ApplicationRecord
  belongs_to :user
  has_many :notification_deliveries, dependent: :destroy
  has_many :reminder_notification_channels, dependent: :destroy
  has_many :reminders, through: :reminder_notification_channels
  has_many :pet_tag_notification_channels, dependent: :destroy
  has_many :pet_tags, through: :pet_tag_notification_channels

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

  def ready_for_delivery?
    enabled? && configuration_issues.empty?
  end

  def configuration_issues
    case channel_type
    when "email" then email_configuration_issues
    when "telegram" then telegram_configuration_issues
    when "vk" then vk_configuration_issues
    when "web_push" then web_push_configuration_issues
    else ["Неизвестный тип канала"]
    end
  end

  def mark_verified!
    update!(verified_at: Time.current) unless verified?
  end

  private

  def web_push_settings_present
    return if settings["endpoint"].present? && settings["p256dh"].present? && settings["auth"].present?

    errors.add(:settings, :blank)
  end

  def email_configuration_issues
    address.present? ? [] : ["Укажите эл. почту"]
  end

  def telegram_configuration_issues
    issues = []
    issues << "Укажите chat_id Telegram" if address.blank?
    issues << "Задайте TELEGRAM_BOT_TOKEN в окружении" if ENV["TELEGRAM_BOT_TOKEN"].blank?
    issues
  end

  def vk_configuration_issues
    issues = []
    issues << "Укажите peer_id VK" if address.blank?
    issues << "Задайте VK_GROUP_TOKEN в окружении" if ENV["VK_GROUP_TOKEN"].blank?
    issues
  end

  def web_push_configuration_issues
    issues = []
    issues << "Нет endpoint push-подписки" if settings["endpoint"].blank?
    issues << "Нет ключа p256dh push-подписки" if settings["p256dh"].blank?
    issues << "Нет ключа auth push-подписки" if settings["auth"].blank?
    issues << "Задайте VAPID_PUBLIC_KEY в окружении" if ENV["VAPID_PUBLIC_KEY"].blank?
    issues << "Задайте VAPID_PRIVATE_KEY в окружении" if ENV["VAPID_PRIVATE_KEY"].blank?
    issues
  end
end
