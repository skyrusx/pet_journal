module PetTagsHelper
  NOTIFICATION_LABELS = {
    "lost_mode" => "Только в Lost Mode",
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
    return "Lost Mode" if pet_tag.lost_mode_enabled?

    pet_tag.enabled? ? "Активен" : "Отключен"
  end

  def pet_tag_status_class(pet_tag)
    return "status-pill muted" if pet_tag.blank? || !pet_tag.persisted?
    return "lost-pill" if pet_tag.lost_mode_enabled?

    pet_tag.enabled? ? "status-pill success" : "status-pill muted"
  end

  def pet_tag_primary_signal(pet_tag, latest_scan = nil)
    return "Создайте QR-профиль безопасности" if pet_tag.blank? || !pet_tag.persisted?
    return "Питомец отмечен как потерявшийся" if pet_tag.lost_mode_enabled?
    return "Публичная страница отключена" unless pet_tag.enabled?
    return "Последнее открытие #{scan_time_label(latest_scan)}" if latest_scan.present?

    "QR-профиль готов к печати"
  end

  def pet_tag_visibility_rows(pet_tag)
    [
      ["Фото и имя", "Показываются"],
      ["Сообщение владельца", pet_tag.public_message.present? ? "Показывается" : "Не заполнено"],
      ["Поведение", pet_tag.behavior_notes.present? ? "Показывается" : "Не заполнено"],
      ["Медицинские заметки", pet_tag.medical_notes.present? ? "Показываются" : "Не заполнено"],
      ["Телефон", pet_tag.show_phone? && pet_tag.contact_phone.present? ? "Показывается" : "Скрыт"],
      ["Email владельца", "Скрыт"]
    ]
  end
end
