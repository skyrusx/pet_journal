module PetProfileSharesHelper
  def profile_share_detail_options
    [["Кратко", "brief"], ["Полностью", "full"]]
  end

  def profile_share_expiration_options
    [
      ["1 день", "one_day"],
      ["7 дней", "seven_days"],
      ["30 дней", "thirty_days"],
      ["Без срока", "never"],
      ["Своя дата", "custom"]
    ]
  end

  def profile_share_status_label(share)
    return "Отключен" unless share.enabled?
    return "Истек" if share.expired?

    "Активен"
  end

  def profile_share_status_class(share)
    return "status-pill muted" unless share.enabled?
    return "lost-pill" if share.expired?

    "status-pill success"
  end

  def profile_share_expiry_label(share)
    return "Без срока" if share.expires_at.blank?

    "До #{share.expires_at.strftime("%d.%m.%Y %H:%M")}"
  end

  def profile_share_section_rows(share)
    [
      ["Профиль", share.show_profile?],
      ["Журнал", share.show_journal?],
      ["Документы", share.show_documents?],
      ["Напоминания", share.show_reminders?],
      ["Жетон", share.show_pet_tag?],
      ["Контакт владельца", share.show_owner_contact?],
      ["Скачивание файлов", share.allow_file_downloads?]
    ]
  end

  def profile_share_public_url(share)
    public_pet_profile_share_url(share.public_token)
  end
end
