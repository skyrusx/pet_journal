namespace :notifications do
  desc "Register the PetJournal Telegram webhook"
  task setup_telegram_webhook: :environment do
    host = ENV.fetch("APP_HOST")
    protocol = ENV.fetch("APP_PROTOCOL", "https")
    secret = ENV.fetch("TELEGRAM_WEBHOOK_SECRET")
    ENV.fetch("TELEGRAM_BOT_TOKEN")
    ENV.fetch("TELEGRAM_BOT_USERNAME")

    url = "#{protocol}://#{host}#{Rails.application.routes.url_helpers.telegram_webhook_path}"
    NotificationChannelConnectors::TelegramBot.set_webhook(url: url, secret_token: secret)

    puts "Telegram webhook configured: #{url}"
  end
end
