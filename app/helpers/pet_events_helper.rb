module PetEventsHelper
  RUSSIAN_MONTHS = {
    1 => "январь",
    2 => "февраль",
    3 => "март",
    4 => "апрель",
    5 => "май",
    6 => "июнь",
    7 => "июль",
    8 => "август",
    9 => "сентябрь",
    10 => "октябрь",
    11 => "ноябрь",
    12 => "декабрь"
  }.freeze

  def event_filter_path(pet, event_type)
    pet_pet_events_path(pet, journal_filter_params.merge(type: event_type).compact_blank)
  end

  def event_filter_class(selected_event_type, event_type)
    classes = ["filter-chip"]
    classes << "active" if selected_event_type == event_type
    classes.join(" ")
  end

  def event_period_filters(pet, selected_period)
    [
      ["Все время", "all"],
      ["Месяц", "month"],
      ["3 месяца", "quarter"],
      ["Год", "year"]
    ].map do |label, period|
      [label, pet_pet_events_path(pet, journal_filter_params.merge(period:).compact_blank), (selected_period.presence || "all") == period]
    end
  end

  def event_status_filters(pet, selected_status)
    [
      ["Все записи", "all"],
      ["С файлами", "with_files"],
      ["С будущим действием", "follow_up"]
    ].map do |label, status|
      [label, pet_pet_events_path(pet, journal_filter_params.merge(status:).compact_blank), (selected_status.presence || "all") == status]
    end
  end

  def journal_filter_summary(selected_event_type, selected_period, selected_status, query)
    filters = []
    filters << PetEvent::EVENT_TYPE_LABELS[selected_event_type] if selected_event_type.present?
    filters << { "month" => "за месяц", "quarter" => "за 3 месяца", "year" => "за год" }[selected_period]
    filters << { "with_files" => "с файлами", "follow_up" => "с будущим действием" }[selected_status]
    filters << "поиск: #{query}" if query.present?

    filters.compact.presence&.join(" · ") || "Показаны все записи"
  end

  def event_month_label(date)
    "#{RUSSIAN_MONTHS.fetch(date.month)} #{date.year}".capitalize
  end

  def event_date_label(date)
    date.strftime("%d.%m.%Y")
  end

  def event_attachment_label(event)
    count = event.files.size
    return if count.zero?

    "#{count} #{russian_plural(count, "файл", "файла", "файлов")}"
  end

  def event_tone(event_type)
    {
      "note" => "neutral",
      "vaccination" => "success",
      "treatment" => "warning",
      "visit" => "info",
      "illness" => "danger",
      "weight" => "neutral",
      "document" => "info"
    }.fetch(event_type.to_s, "neutral")
  end

  def event_type_hint(event_type)
    {
      "note" => "Общее наблюдение или важная заметка.",
      "vaccination" => "Прививки, ревакцинация и отметки в паспорте.",
      "treatment" => "Обработка, лекарства, процедуры и уход.",
      "visit" => "Приемы у врача, рекомендации и назначения.",
      "illness" => "Симптомы, ухудшение самочувствия и лечение.",
      "weight" => "Контроль веса и динамика изменений.",
      "document" => "Паспорт, анализ, справка, назначение или чек."
    }.fetch(event_type.to_s, "Запись в журнале питомца.")
  end

  def event_file_label(file)
    "#{file.filename} · #{number_to_human_size(file.byte_size)}"
  end

  def event_severity_options
    PetEvent.severities.keys.map { |key| [I18n.t("pet_events.severities.#{key}"), key] }
  end

  def event_structured_summary(event)
    summary = event.summary
    return event_type_hint(event.event_type) if summary.blank?

    truncate(summary.to_s, length: 190)
  end

  def quick_event_actions(pet)
    [
      ["Вес", new_pet_pet_event_path(pet, type: :weight)],
      ["Прививка", new_pet_pet_event_path(pet, type: :vaccination)],
      ["Визит", new_pet_pet_event_path(pet, type: :visit)],
      ["Документ", new_pet_pet_document_path(pet)],
      ["Заметка", new_pet_pet_event_path(pet, type: :note)]
    ]
  end

  private

  def journal_filter_params
    {
      q: params[:q].presence,
      type: params[:type].presence,
      period: params[:period].presence,
      status: params[:status].presence
    }
  end
end
