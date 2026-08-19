module ApplicationHelper
  def russian_plural(number, one, few, many)
    return many if (11..14).cover?(number % 100)

    case number % 10
    when 1 then one
    when 2..4 then few
    else many
    end
  end

  def app_nav_link(label, path, active: false, **options)
    classes = class_names("app-nav-link", active: active)
    link_to(label, path, options.merge(class: classes))
  end

  def pj_icon(name, **options)
    paths = {
      home: '<path d="M3 10.8 12 3l9 7.8v9.7a.5.5 0 0 1-.5.5H15v-6H9v6H3.5a.5.5 0 0 1-.5-.5z"/>',
      journal: '<path d="M6 4.5h9a3 3 0 0 1 3 3V20H8a3 3 0 0 0-3 3V6a1.5 1.5 0 0 1 1-1.5z"/><path d="M8 16h7M8 12h7M8 8h5"/>',
      plus: '<path d="M12 5v14M5 12h14"/>',
      clock: '<circle cx="12" cy="12" r="8.5"/><path d="M12 7.5V12l3 2"/>',
      more: '<circle cx="5" cy="12" r="1.5"/><circle cx="12" cy="12" r="1.5"/><circle cx="19" cy="12" r="1.5"/>',
      paw: '<circle cx="7.2" cy="8.3" r="2"/><circle cx="12" cy="6.6" r="2"/><circle cx="16.8" cy="8.3" r="2"/><path d="M6.2 16.2c.5-3 3.1-5.2 5.8-5.2s5.3 2.2 5.8 5.2c.3 1.8-1 3.3-2.8 3.3-.9 0-1.7-.3-3-.3s-2.1.3-3 .3c-1.8 0-3.1-1.5-2.8-3.3z"/>',
      tag: '<path d="M4 12.5 12.5 4H20v7.5L11.5 20 4 12.5z"/><circle cx="16.5" cy="7.5" r="1.3"/>',
      bell: '<path d="M18 10.5a6 6 0 0 0-12 0c0 5-2 5.5-2 7h16c0-1.5-2-2-2-7z"/><path d="M10 20a2.2 2.2 0 0 0 4 0"/>',
      user: '<circle cx="12" cy="8" r="3.5"/><path d="M5 20c.9-3.7 3.5-6 7-6s6.1 2.3 7 6"/>',
      settings: '<circle cx="12" cy="12" r="3"/><path d="M19 12a7.2 7.2 0 0 0-.1-1.1l2-1.5-2-3.4-2.4 1a7.7 7.7 0 0 0-1.9-1.1L14.3 3h-4.6l-.3 2.9A7.7 7.7 0 0 0 7.5 7l-2.4-1-2 3.4 2 1.5A7.2 7.2 0 0 0 5 12c0 .4 0 .8.1 1.1l-2 1.5 2 3.4 2.4-1c.6.5 1.2.8 1.9 1.1l.3 2.9h4.6l.3-2.9c.7-.3 1.3-.6 1.9-1.1l2.4 1 2-3.4-2-1.5c.1-.3.1-.7.1-1.1z"/>',
      file: '<path d="M7 3.5h7l3 3V20.5H7z"/><path d="M14 3.5V7h3"/><path d="M9.5 12h5M9.5 15.5h5"/>',
      share: '<circle cx="7" cy="12" r="2.5"/><circle cx="17" cy="7" r="2.5"/><circle cx="17" cy="17" r="2.5"/><path d="m9.2 10.8 5.6-2.7M9.2 13.2l5.6 2.7"/>',
      logout: '<path d="M10 5H5v14h5"/><path d="M14 8l4 4-4 4M18 12H9"/>',
      chevron: '<path d="m9 6 6 6-6 6"/>'
    }

    svg_options = options.reverse_merge(
      aria: { hidden: true },
      viewBox: "0 0 24 24",
      fill: "none",
      xmlns: "http://www.w3.org/2000/svg"
    )
    svg_options[:class] = class_names("pj-nav-icon", options[:class])

    content_tag(
      :svg,
      paths.fetch(name).html_safe,
      svg_options
    )
  end

  def current_mobile_pet
    @pet if defined?(@pet) && @pet.present? && @pet.persisted?
  end

  def mobile_nav_pet
    current_mobile_pet || current_user&.pets&.order(created_at: :desc)&.first
  end

  def mobile_bottom_nav_items
    pet = mobile_nav_pet
    [
      { key: :home, label: "Главная", path: root_path, icon: :home, active: mobile_nav_active?(:home) },
      { key: :journal, label: "Журнал", path: pet.present? ? pet_pet_events_path(pet) : pets_path, icon: :journal, active: mobile_nav_active?(:journal) },
      { key: :reminders, label: "Напом.", aria_label: "Напоминания", path: pet.present? ? pet_reminders_path(pet) : pets_path, icon: :clock, active: mobile_nav_active?(:reminders), badge: mobile_reminders_badge },
      { key: :more, label: "Ещё", icon: :more, active: mobile_nav_active?(:more) }
    ]
  end

  def mobile_add_actions
    pet = mobile_nav_pet
    return [{ label: "Питомца", path: new_pet_path, icon: :paw }] unless pet.present?

    [
      { label: "Событие в журнал", path: new_pet_pet_event_path(pet), icon: :journal },
      { label: "Напоминание", path: new_pet_reminder_path(pet), icon: :clock },
      { label: "Вес", path: new_pet_pet_event_path(pet, type: :weight), icon: :plus },
      { label: "Лекарство / обработка", path: new_pet_pet_event_path(pet, type: :treatment), icon: :plus },
      { label: "Вакцинация", path: new_pet_pet_event_path(pet, type: :vaccination), icon: :plus },
      { label: "Документ", path: new_pet_pet_document_path(pet), icon: :file }
    ]
  end

  def mobile_more_menu_items
    pet = mobile_nav_pet
    items = [
      { label: "Мои питомцы", path: pets_path, icon: :paw, active: controller_name == "pets" },
      { label: "Настройки уведомлений", path: notification_channels_path, icon: :bell, active: controller_name == "notification_channels" },
      { label: "Аккаунт", path: edit_user_registration_path, icon: :user, active: devise_controller? }
    ]

    if pet.present?
      items.insert(1, { label: "PetTag", path: pet_pet_tag_path(pet), icon: :tag, active: controller_name == "pet_tags" })
      items.insert(2, { label: "Документы", path: pet_pet_documents_path(pet), icon: :file, active: controller_name == "pet_documents" })
      items.insert(3, { label: "Доступ", path: pet_profile_shares_path(pet), icon: :share, active: controller_name == "pet_profile_shares" })
    end

    items
  end

  def mobile_nav_active?(section)
    case section
    when :home
      controller_name == "pages" && action_name == "index"
    when :journal
      controller_name == "pet_events"
    when :reminders
      controller_name == "reminders"
    when :more
      %w[pets pet_tags pet_documents pet_profile_shares notification_channels].include?(controller_name) || devise_controller?
    else
      false
    end
  end

  def mobile_reminders_badge
    return unless user_signed_in?

    count = current_user.reminders.overdue.count
    count = current_user.reminders.status_active.where(next_run_at: Time.current.beginning_of_day..Time.current.end_of_day).count if count.zero?
    count.positive? ? [count, 9].min : nil
  end

  # The bell opens notification settings/history, not a notification inbox.
  # Reminder urgency is shown only on the dedicated Reminders navigation item.
  def mobile_notifications_badge
    nil
  end

  def pet_nav_items(pet)
    [
      ["Обзор", pet_path(pet), controller_name == "pets" && action_name == "show"],
      ["Журнал", pet_pet_events_path(pet), controller_name == "pet_events"],
      ["Напоминания", pet_reminders_path(pet), controller_name == "reminders"],
      ["Документы", pet_pet_documents_path(pet), controller_name == "pet_documents"],
      ["PetTag", pet_pet_tag_path(pet), controller_name == "pet_tags"],
      ["Доступ", pet_profile_shares_path(pet), controller_name == "pet_profile_shares"],
      ["Данные", edit_pet_path(pet), controller_name == "pets" && action_name == "edit"]
    ]
  end
end
