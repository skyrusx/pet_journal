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
    event_type.present? ? pet_pet_events_path(pet, type: event_type) : pet_pet_events_path(pet)
  end

  def event_filter_class(selected_event_type, event_type)
    classes = ["filter-chip"]
    classes << "active" if selected_event_type == event_type
    classes.join(" ")
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
end
