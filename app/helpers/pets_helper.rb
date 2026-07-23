module PetsHelper
  def pet_age(pet)
    return "Возраст не указан" if pet.birth_date.blank?

    years = ((Date.current - pet.birth_date).to_i / 365.25).floor
    return "Младше года" if years.zero?

    "#{years} #{russian_plural(years, "год", "года", "лет")}"
  end

  def pet_short_description(pet)
    [pet.species.presence, pet.breed.presence].compact.join(" · ").presence || "Данные не заполнены"
  end

  def pet_sex_label(pet)
    return "Мальчик" if pet.sex == 0
    return "Девочка" if pet.sex == 1

    "—"
  end

  def pet_weight_label(weight)
    return "—" if weight.blank?

    "#{number_with_precision(weight, precision: 2, strip_insignificant_zeros: true)} кг"
  end

  def pet_event_summary(event)
    return "Добавьте первую запись" if event.blank?

    title = event.title.presence || event.event_type_label
    "#{event.event_date.strftime("%d.%m.%Y")} · #{title}"
  end

  def pet_signal_label(event)
    return "Нужна первая запись" if event.blank?

    event.event_type_label
  end

  def pet_overview_signal(pet, pet_tag, latest_scan, latest_event, next_reminder = nil)
    if pet_tag&.lost_mode_enabled?
      return {
        tone: "danger",
        label: "Режим потери",
        title: "Питомец отмечен как потерявшийся",
        body: pet_tag.lost_message.presence || "Проверьте публичную страницу и контакт для связи."
      }
    end

    if next_reminder&.overdue?
      return {
        tone: "danger",
        label: "Напоминание просрочено",
        title: next_reminder.title,
        body: "Срок был #{next_reminder.next_run_at.strftime("%d.%m.%Y %H:%M")}."
      }
    end

    if next_reminder&.due_today?
      return {
        tone: "warning",
        label: "Сегодня",
        title: next_reminder.title,
        body: "Напоминание на #{next_reminder.next_run_at.strftime("%H:%M")}."
      }
    end

    if latest_scan.present?
      return {
        tone: "success",
        label: "PetTag",
        title: "QR-профиль недавно открывали",
        body: "Последнее сканирование #{latest_scan.created_at.strftime("%d.%m.%Y %H:%M")}."
      }
    end

    if latest_event.present?
      return {
        tone: "neutral",
        label: latest_event.event_type_label,
        title: latest_event.title.presence || latest_event.event_type_label,
        body: "Последняя запись от #{latest_event.event_date.strftime("%d.%m.%Y")}."
      }
    end

    {
      tone: "warning",
      label: "Старт",
      title: "Добавьте первую запись в журнал",
      body: "Так обзор начнет показывать историю здоровья и ухода."
    }
  end

  def pet_profile_completion_items(pet, pet_tag)
    [
      ["Фото", pet.photo.attached?],
      ["Дата рождения", pet.birth_date.present?],
      ["Вес", pet.weight.present?],
      ["Чип", pet.chip_number.present?],
      ["PetTag", pet_tag&.persisted?]
    ]
  end

  def pet_profile_completion_percent(pet, pet_tag)
    items = pet_profile_completion_items(pet, pet_tag)
    completed = items.count { |_label, done| done }

    ((completed.to_f / items.size) * 100).round
  end
end
