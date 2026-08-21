module RemindersHelper
  def reminder_type_options
    Reminder.reminder_types.keys.map { |key| [I18n.t("reminders.types.#{key}"), key] }
  end

  def repeat_rule_options
    Reminder.repeat_rules.keys.map { |key| [I18n.t("reminders.repeat_rules.#{key}"), key] }
  end

  def repeat_unit_options
    Reminder.repeat_units.keys.map { |key| [I18n.t("reminders.repeat_units.#{key}", count: 2), key] }
  end

  def reminder_status_filters(pet, selected_status)
    [
      ["Активные", "active"],
      ["Сегодня", "today"],
      ["Просроченные", "overdue"],
      ["Пауза", "paused"],
      ["Выполненные", "completed"],
      ["Все", "all"]
    ].map do |label, status|
      [label, pet_reminders_path(pet, status:, type: params[:type].presence), selected_status == status]
    end
  end

  def reminder_type_filters(pet, selected_type, selected_status)
    [["Все типы", nil, selected_type.blank?]] +
      Reminder.reminder_types.keys.map do |type|
        [I18n.t("reminders.types.#{type}"), pet_reminders_path(pet, status: selected_status, type:), selected_type == type]
      end
  end

  def reminder_filter_class(active)
    class_names("filter-chip", active:)
  end

  def reminder_datetime_presets
    [
      ["Через 1 час", 1.hour.from_now],
      ["Завтра утром", 1.day.from_now.change(hour: 9, min: 0, sec: 0)],
      ["Через месяц", 1.month.from_now.change(sec: 0)],
      ["Через год", 1.year.from_now.change(sec: 0)]
    ]
  end

  def reminder_status_class(reminder)
    return "lost-pill" if reminder.overdue?
    return "status-pill success" if reminder.due_today?
    return "status-pill muted" if reminder.status_paused?
    return "status-pill muted" if reminder.status_completed?

    "status-pill"
  end

  def reminder_status_label(reminder)
    return "Просрочено" if reminder.overdue?
    return "Сегодня" if reminder.due_today?

    I18n.t("reminders.statuses.#{reminder.status}")
  end

  def reminder_status_tone(reminder)
    return "is-overdue" if reminder.overdue?
    return "is-completed" if reminder.status_completed?
    return "is-paused" if reminder.status_paused?

    "is-active"
  end

  def reminder_type_tone(reminder_or_type)
    type = reminder_or_type.respond_to?(:reminder_type) ? reminder_or_type.reminder_type : reminder_or_type.to_s
    {
      "vaccination" => "is-vaccination",
      "medication" => "is-medication",
      "treatment" => "is-treatment",
      "visit" => "is-visit",
      "weight" => "is-weight",
      "other" => "is-other"
    }.fetch(type, "is-other")
  end

  def reminder_type_icon(type)
    path = case type.to_s
           when "vaccination"
             '<path d="M8 5h8M9 3v4M15 3v4M7 9h10v10H7z"/><path d="M9.5 12.5h5M12 10v5"/>'
           when "medication"
             '<path d="M8.2 6.2a4 4 0 0 1 5.6 0l4 4a4 4 0 0 1-5.6 5.6l-4-4a4 4 0 0 1 0-5.6z"/><path d="m10 8 6 6"/>'
           when "treatment"
             '<path d="M12 3v18M7 7h10M7 17h10"/><path d="m6 5 12 14M18 5 6 19"/>'
           when "visit"
             '<path d="M12 20s6-5.1 6-10A6 6 0 1 0 6 10c0 4.9 6 10 6 10z"/><circle cx="12" cy="10" r="2"/>'
           when "weight"
             '<path d="M5 7h14l-1 12H6L5 7z"/><path d="M9 7a3 3 0 0 1 6 0M12 10v3"/>'
           else
             '<path d="M6 5h12v14H6z"/><path d="M9 9h6M9 13h6"/>'
           end

    content_tag(
      :svg,
      path.html_safe,
      viewBox: "0 0 24 24",
      fill: "none",
      aria: { hidden: true },
      class: "pj-reminder-type-icon"
    )
  end

  def reminder_channels_label(reminder)
    return "Все включенные каналы" if reminder.notification_channels.empty?

    reminder.notification_channels.map(&:channel_type_label).uniq.to_sentence
  end

  def reminder_completion_label(completion)
    if completion.pet_event.present?
      link_to "Запись в журнале", pet_pet_event_path(completion.reminder.pet, completion.pet_event), class: "text-decoration-none"
    elsif completion.event_created?
      "Запись удалена"
    else
      "Без записи"
    end
  end

  def reminder_filter_summary(selected_status, selected_type)
    filters = []
    filters << {
      "active" => "активные",
      "today" => "сегодня",
      "overdue" => "просроченные",
      "paused" => "на паузе",
      "completed" => "выполненные"
    }[selected_status]
    filters << I18n.t("reminders.types.#{selected_type}") if selected_type.present?

    filters.compact.presence&.join(" · ") || "все напоминания"
  end

  def quick_reminder_actions(pet)
    [
      ["Лекарство", new_pet_reminder_path(pet, type: :medication)],
      ["Вакцинация", new_pet_reminder_path(pet, type: :vaccination)],
      ["Обработка от паразитов", new_pet_reminder_path(pet, type: :treatment)],
      ["Визит к врачу", new_pet_reminder_path(pet, type: :visit)],
      ["Вес", new_pet_reminder_path(pet, type: :weight)]
    ]
  end
end
