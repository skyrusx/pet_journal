module RemindersHelper
  def reminder_type_options
    Reminder.reminder_types.keys.map { |key| [I18n.t("reminders.types.#{key}"), key] }
  end

  def repeat_rule_options
    Reminder.repeat_rules.keys.map { |key| [I18n.t("reminders.repeat_rules.#{key}"), key] }
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
end
