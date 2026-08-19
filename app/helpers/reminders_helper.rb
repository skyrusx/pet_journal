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
