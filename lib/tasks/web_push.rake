namespace :web_push do
  desc "Generate a VAPID key pair for PetJournal Web Push"
  task vapid: :environment do
    require "webpush"

    key = Webpush.generate_key

    puts "VAPID_PUBLIC_KEY=#{key.public_key}"
    puts "VAPID_PRIVATE_KEY=#{key.private_key}"
    puts "VAPID_SUBJECT=mailto:support@pet-journal.ru"
    puts
    puts "Сохраните private key только в переменных окружения сервера или Rails credentials."
    puts "Не добавляйте VAPID_PRIVATE_KEY в Git."
  end
end
