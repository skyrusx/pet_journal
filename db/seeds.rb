unless Rails.env.development? || ENV["LOAD_DEMO_SEEDS"] == "true"
  puts "Demo seeds skipped outside development. Set LOAD_DEMO_SEEDS=true to run explicitly."
  exit
end

require "chunky_png"
require "stringio"

password = ENV.fetch("PETJOURNAL_SEED_PASSWORD") do
  raise "Set PETJOURNAL_SEED_PASSWORD outside development" unless Rails.env.development?

  "demo-password"
end

def seed_user(email, password)
  user = User.find_or_initialize_by(email:)
  if user.new_record?
    user.password = password
    user.password_confirmation = password
  end
  user.save!
  user
end

def attach_seed_png(record, name, color)
  return if record.photo.attached?

  png = ChunkyPNG::Image.new(320, 320, ChunkyPNG::Color::TRANSPARENT)
  fill = ChunkyPNG::Color.from_hex(color)
  320.times do |x|
    320.times do |y|
      dx = x - 160
      dy = y - 160
      png[x, y] = fill if (dx * dx) + (dy * dy) <= 130 * 130
    end
  end
  record.photo.attach(
    io: StringIO.new(png.to_blob),
    filename: "#{name.parameterize}.png",
    content_type: "image/png"
  )
end

def upsert_child(scope, lookup, attributes)
  record = scope.find_or_initialize_by(lookup)
  record.assign_attributes(attributes)
  record.save!
  record
end

demo = seed_user("demo@petjournal.local", password)
empty = seed_user("empty@petjournal.local", password)

barsik = upsert_child(demo.pets, { name: "Барсик" }, {
  species: "Кошка",
  breed: "Европейская короткошерстная",
  sex: 0,
  birth_date: 4.years.ago.to_date,
  weight: 5.2,
  color: "Рыжий с белой грудкой",
  chip_number: "643094100000321",
  passport_number: "PJ-2024-0412",
  neutered: true,
  notes: "Спокойный дома, волнуется в переноске. Любит влажный корм с индейкой."
})

luna = upsert_child(demo.pets, { name: "Луна" }, {
  species: "Собака",
  breed: "Метис",
  sex: 1,
  birth_date: 1.year.ago.to_date,
  weight: 11.4,
  color: "Черная",
  neutered: false,
  notes: nil
})

marcel = upsert_child(demo.pets, { name: "Марсель Великий Путешественник" }, {
  species: "Кот",
  breed: "Пушистый домашний компаньон с очень длинным названием породы",
  sex: 0,
  birth_date: 7.years.ago.to_date,
  weight: 6.75,
  color: "Серебристо-дымчатый с длинным описанием окраса для проверки переносов",
  chip_number: "643094100000999",
  passport_number: "LONG-PASSPORT-NUMBER-PJ-2026-00000042",
  neutered: true,
  notes: "Длинная заметка для проверки карточек: спокойно переносит поездки, но не любит громкие звуки и просит воду после прогулки."
})

attach_seed_png(barsik, "barsik", "#efa47d")
attach_seed_png(marcel, "marcel", "#dcece3")

events = [
  [barsik, "visit", "Плановый осмотр", Date.current, { clinic_name: "Ветклиника Север", veterinarian_name: "Ирина Павлова", description: "Осмотр без замечаний. Рекомендовано продолжать обычный рацион." }],
  [barsik, "vaccination", "Ежегодная вакцинация", 12.days.ago.to_date, { vaccine_name: "Комплексная вакцина", vaccine_batch: "VAC-24A", clinic_name: "Ветклиника Север", veterinarian_name: "Ирина Павлова", valid_until: 1.year.from_now.to_date, description: "Перенес вакцинацию спокойно." }],
  [barsik, "treatment", "Обработка от паразитов", 1.month.ago.to_date, { medication_name: "Капли на холку", dosage: "1 пипетка", course_started_on: 1.month.ago.to_date, course_ended_on: 1.month.ago.to_date, next_action_at: 2.months.from_now.change(hour: 10), description: nil }],
  [barsik, "weight", "Контроль веса", 2.months.ago.to_date, { weight_value: 5.2, weight_unit: "kg", description: "Вес стабилен после смены корма." }],
  [barsik, "note", "Наблюдение владельца", 4.months.ago.to_date, { description: "После переезда быстрее устает вечером. Аппетит хороший, воду пьет как обычно, активность днем сохраняется." }],
  [luna, "note", "Питание", 3.days.ago.to_date, { description: "Перешли на новый корм постепенно, реакция нормальная." }],
  [luna, "visit", "Груминг", 2.months.ago.to_date, { clinic_name: "Груминг рядом", description: "Стрижка когтей и вычесывание." }],
  [marcel, "treatment", "Прием лекарства после консультации с очень длинным названием записи", 8.days.ago.to_date, { medication_name: "Поддерживающий препарат", dosage: "1/2 таблетки утром", course_started_on: 8.days.ago.to_date, course_ended_on: 2.days.from_now.to_date, description: "Длинное описание: препарат даем после еды, отмечаем аппетит, настроение и сон. Если появится вялость или отказ от воды, нужно связаться с ветеринаром." }],
  [marcel, "weight", "Изменение веса", 5.months.ago.to_date, { weight_value: 6.75, weight_unit: "kg" }]
]

events.each do |pet, type, title, date, attrs|
  upsert_child(pet.pet_events, { event_type: type, title:, event_date: date }, attrs)
end

reminders = [
  [barsik, "Дать лекарство сегодня", "medication", Time.current.change(hour: 20), "once", "active", "После вечернего кормления."],
  [barsik, "Ежегодная вакцинация", "vaccination", 10.days.from_now.change(hour: 9), "yearly", "active", "Записаться за неделю."],
  [barsik, "Просроченная обработка от клещей", "treatment", 3.days.ago.change(hour: 10), "monthly", "active", "Проверить запас препарата."],
  [luna, "Плановый осмотр", "visit", 20.days.from_now.change(hour: 12), "once", "active", nil],
  [luna, "Купить корм", "other", 1.day.from_now.change(hour: 18), "monthly", "paused", "Большая упаковка привычного корма."],
  [marcel, "Очень длинное напоминание для проверки переноса текста в карточке и списке задач", "other", 5.days.from_now.change(hour: 11), "weekly", "completed", "Закрытая задача для визуальной проверки статуса."]
]

reminders.each do |pet, title, type, time, repeat, status, note|
  reminder = upsert_child(pet.reminders, { title: }, {
    reminder_type: type,
    remind_at: time,
    next_run_at: time,
    repeat_rule: repeat,
    status: status,
    note: note
  })
  reminder.update!(last_completed_at: 1.day.ago) if reminder.status_completed? && reminder.last_completed_at.blank?
end

documents = [
  [barsik, "Ветеринарный паспорт", "passport", 2.years.ago.to_date, nil, "Ветклиника Север", "PJ-2024-0412"],
  [barsik, "Справка о вакцинации", "vaccination", 12.days.ago.to_date, 1.year.from_now.to_date, "Ветклиника Север", "VAC-24A"],
  [barsik, "Назначение препарата", "prescription", 8.days.ago.to_date, 10.days.from_now.to_date, "Ветклиника Север", "RX-117"],
  [luna, "Справка для поездки", "certificate", 2.months.ago.to_date, 1.week.ago.to_date, "Городская ветстанция", "CERT-58"],
  [marcel, "Очень длинное название документа для проверки переносов в карточке документа и списке вложений", "lab_result", 1.month.ago.to_date, 2.months.from_now.to_date, "Лаборатория Забота", "LAB-LONG-2026-0001"]
]

documents.each do |pet, title, type, issued_on, expires_on, issuer, number|
  doc = upsert_child(pet.pet_documents, { title: }, {
    document_type: type,
    issued_on: issued_on,
    expires_on: expires_on,
    issuer: issuer,
    number: number,
    expiry_reminder_days: 14,
    notes: "Демо-документ для ручной проверки интерфейса."
  })
  next if doc.files.attached?

  doc.files.attach(
    io: StringIO.new("PetJournal demo document: #{title}\n"),
    filename: "#{title.parameterize}.txt",
    content_type: "text/plain"
  )
end

tag = barsik.pet_tag || barsik.build_pet_tag
tag.assign_attributes(
  enabled: true,
  public_message: "Если вы нашли Барсика, пожалуйста, напишите владельцу.",
  behavior_notes: "Может прятаться в тихом месте, на руки идет не сразу.",
  medical_notes: "Срочных лекарств нет.",
  contact_phone: "+7 900 000-00-00",
  show_phone: true,
  show_medical_notes: true,
  safety_status: :safe,
  notification_preference: :lost_mode
)
tag.save!

marcel_tag = marcel.pet_tag || marcel.build_pet_tag
marcel_tag.assign_attributes(
  enabled: true,
  public_message: "Марсель дружелюбный, но пугается громких улиц.",
  behavior_notes: "Подходит на спокойный голос.",
  medical_notes: "Есть чувствительность к некоторым кормам.",
  show_phone: false,
  show_medical_notes: false,
  safety_status: :reunited,
  notification_preference: :never
)
marcel_tag.save!

2.times do |index|
  scan = tag.pet_tag_scans.where(user_agent: "PetJournal seed browser", location_note: index.zero? ? "Рядом с подъездом" : nil).first_or_initialize
  scan.assign_attributes(
    user_agent: "PetJournal seed browser",
    referrer: "https://example.local/map",
    latitude: 55.75 + index,
    longitude: 37.61 + index,
    location_note: index.zero? ? "Рядом с подъездом" : nil,
    location_shared_at: index.zero? ? 2.days.ago : nil,
    scan_status: index.zero? ? :location_shared : :scanned,
    created_at: (index + 1).days.ago
  )
  scan.save!
end

share = upsert_child(barsik.pet_profile_shares, { title: "Профиль для ветеринара" }, {
  enabled: true,
  expires_at: 2.weeks.from_now,
  detail_level: :full,
  show_profile: true,
  show_journal: true,
  show_documents: true,
  show_reminders: true,
  show_pet_tag: true,
  show_owner_contact: false,
  allow_file_downloads: false
})

expired_share = upsert_child(marcel.pet_profile_shares, { title: "Истекшая ссылка для поездки" }, {
  enabled: false,
  expires_at: 1.day.ago,
  detail_level: :brief,
  show_profile: true,
  show_journal: false,
  show_documents: true,
  show_reminders: false,
  show_pet_tag: false,
  show_owner_contact: false,
  allow_file_downloads: false
})

[share, expired_share].each_with_index do |profile_share, index|
  view = profile_share.pet_profile_share_views.where(user_agent: "PetJournal seed browser", referrer: "https://example.local").first_or_initialize
  view.assign_attributes(
    public_token: profile_share.public_token,
    user_agent: "PetJournal seed browser",
    referrer: "https://example.local",
    ip_address: "203.0.113.0",
    created_at: (index + 1).hours.ago
  )
  view.save!
end

puts "Demo email: #{demo.email}"
puts "Development password: #{password}" if Rails.env.development?
puts "Empty email: #{empty.email}"
puts "Pets: #{demo.pets.count}"
puts "Events: #{PetEvent.where(pet_id: demo.pet_ids).count}"
puts "Reminders: #{Reminder.where(pet_id: demo.pet_ids).count}"
puts "Documents: #{PetDocument.where(pet_id: demo.pet_ids).count}"
puts "PetTags: #{PetTag.joins(:pet).where(pets: { user_id: demo.id }).count}"
puts "PetTag scans: #{PetTagScan.joins(pet_tag: :pet).where(pets: { user_id: demo.id }).count}"
puts "Profile shares: #{PetProfileShare.joins(:pet).where(pets: { user_id: demo.id }).count}"
puts "Profile share views: #{PetProfileShareView.joins(pet_profile_share: :pet).where(pets: { user_id: demo.id }).count}"
