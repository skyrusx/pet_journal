module PetTagsHelper
  NOTIFICATION_LABELS = {
    "lost_mode" => "Только в режиме потери",
    "always" => "При каждом сканировании",
    "never" => "Не уведомлять"
  }.freeze

  def notification_options
    NOTIFICATION_LABELS.map { |value, label| [label, value] }
  end

  def notification_label(value)
    NOTIFICATION_LABELS.fetch(value, value)
  end

  def scan_time_label(scan)
    scan.created_at.strftime("%d.%m.%Y %H:%M")
  end

  def pet_tag_status_label(pet_tag)
    return "Не создан" if pet_tag.blank? || !pet_tag.persisted?
    return "Потерялся" if pet_tag.status_lost?
    return "Найден" if pet_tag.status_found?
    return "Дома" if pet_tag.status_reunited?

    pet_tag.enabled? ? "Активен" : "Отключен"
  end

  def pet_tag_status_class(pet_tag)
    return "status-pill muted" if pet_tag.blank? || !pet_tag.persisted?
    return "lost-pill" if pet_tag.status_lost?
    return "signal-pill" if pet_tag.status_found?
    return "status-pill success" if pet_tag.status_reunited?

    pet_tag.enabled? ? "status-pill success" : "status-pill muted"
  end

  def pet_tag_primary_signal(pet_tag, latest_scan = nil)
    return "Создайте QR-профиль безопасности" if pet_tag.blank? || !pet_tag.persisted?
    return "Питомец отмечен как потерявшийся" if pet_tag.status_lost?
    return "Питомца нашли, проверьте сообщения" if pet_tag.status_found?
    return "Питомец вернулся домой" if pet_tag.status_reunited?
    return "Публичная страница отключена" unless pet_tag.enabled?
    return "Последнее открытие #{scan_time_label(latest_scan)}" if latest_scan.present?

    "QR-профиль готов к печати"
  end

  def pet_tag_visibility_rows(pet_tag)
    [
      ["Фото и имя", "Показываются"],
      ["Сообщение владельца", pet_tag.public_message.present? ? "Показывается" : "Не заполнено"],
      ["Поведение", pet_tag.behavior_notes.present? ? "Показывается" : "Не заполнено"],
      ["Медицинские заметки", pet_tag.show_medical_notes? && pet_tag.medical_notes.present? ? "Показываются" : "Скрыты"],
      ["Телефон", pet_tag.show_phone? && pet_tag.contact_phone.present? ? "Показывается" : "Скрыт"],
      ["Эл. почта владельца", "Скрыта"]
    ]
  end

  def pet_tag_status_options
    [
      ["В безопасности", "safe"],
      ["Потерялся", "lost"],
      ["Найден", "found"],
      ["Вернулся домой", "reunited"]
    ]
  end

  def scan_status_filters(pet, selected)
    [
      ["Все", "all"],
      ["Сканы", "scanned"],
      ["С геолокацией", "location_shared"],
      ["Нашедшие", "found_reported"]
    ].map { |label, status| [label, pet_pet_tag_path(pet, scan_status: status), selected == status] }
  end

  def scan_status_label(scan)
    I18n.t("pet_tag_scans.statuses.#{scan.scan_status}")
  end

  def scan_status_class(scan)
    return "signal-pill" if scan.status_found_reported?
    return "status-pill success" if scan.location_shared?

    "status-pill muted"
  end
end
