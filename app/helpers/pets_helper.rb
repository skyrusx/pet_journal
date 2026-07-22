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

end
