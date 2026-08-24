require "json"
require "net/http"
require "securerandom"

class PetTagScanNotifier
  def self.notify(scan, event:)
    new(scan, event:).notify
  end

  def initialize(scan, event:)
    @scan = scan
    @pet_tag = scan.pet_tag
    @pet = @pet_tag.pet
    @user = @pet.user
    @event = event
  end

  def notify
    InAppNotification.for_pet_tag_scan!(scan, event:)

    channels = notification_channels
    channels.each { |channel| deliver_to_channel(channel) }
    scan.update!(owner_notified_at: Time.current, notification_error: nil)
  rescue StandardError => e
    scan.update!(notification_error: e.message)
  end

  private

  attr_reader :scan, :pet_tag, :pet, :user, :event

  def notification_channels
    channels = pet_tag.notification_channels.enabled.to_a
    channels = user.notification_channels.enabled.to_a if pet_tag.notification_channels.empty?
    channels.presence || [default_email_channel]
  end

  def default_email_channel
    user.notification_channels.find_or_create_by!(channel_type: :email, address: user.email) do |channel|
      channel.name = "Эл. почта аккаунта"
      channel.enabled = true
      channel.verified_at = Time.current
    end
  end

  def deliver_to_channel(channel)
    case channel.channel_type
    when "email" then deliver_email
    when "telegram" then deliver_telegram(channel)
    when "vk" then deliver_vk(channel)
    when "web_push" then deliver_web_push(channel)
    end
  end

  def deliver_email
    if event == :found
      PetTagMailer.location_shared(scan).deliver_now
    else
      PetTagMailer.scan_notification(scan).deliver_now
    end
  end

  def deliver_telegram(channel)
    token = ENV.fetch("TELEGRAM_BOT_TOKEN")
    uri = URI("https://api.telegram.org/bot#{token}/sendMessage")
    response = Net::HTTP.post(uri, { chat_id: channel.address, text: message_text }.to_json, "Content-Type" => "application/json")
    raise response.body unless response.is_a?(Net::HTTPSuccess)
  end

  def deliver_vk(channel)
    response = Net::HTTP.post_form(URI("https://api.vk.com/method/messages.send"), {
      access_token: ENV.fetch("VK_GROUP_TOKEN"),
      peer_id: channel.address,
      random_id: SecureRandom.random_number(2_147_483_647),
      message: message_text,
      v: ENV.fetch("VK_API_VERSION", "5.199")
    })
    body = JSON.parse(response.body)
    raise body["error"]["error_msg"] if body["error"].present?
  end

  def deliver_web_push(channel)
    require "webpush"

    WebPush.payload_send(
      message: {
        title: "PetTag: #{pet.name}",
        body: message_text.lines.first,
        path: Rails.application.routes.url_helpers.pet_pet_tag_path(pet)
      }.to_json,
      endpoint: channel.settings.fetch("endpoint"),
      p256dh: channel.settings.fetch("p256dh"),
      auth: channel.settings.fetch("auth"),
      vapid: {
        subject: ENV.fetch("VAPID_SUBJECT", "mailto:#{user.email}"),
        public_key: ENV.fetch("VAPID_PUBLIC_KEY"),
        private_key: ENV.fetch("VAPID_PRIVATE_KEY")
      }
    )
  end

  def message_text
    [
      event == :found ? "Нашедший отправил данные по PetTag." : "QR-профиль PetTag открыли.",
      "Питомец: #{pet.name}",
      scan.location_label.present? ? "Место: #{scan.location_label}" : nil,
      scan.finder_name.present? ? "Имя: #{scan.finder_name}" : nil,
      scan.finder_contact.present? ? "Контакт: #{scan.finder_contact}" : nil,
      scan.finder_message.present? ? "Комментарий: #{scan.finder_message}" : nil
    ].compact.join("\n")
  end
end
