class BirthdayGreetingPresenter
  attr_reader :pets, :date

  def initialize(pets:, date:)
    @pets = Array(pets)
    @date = date
  end

  def title
    case pets.size
    when 1
      "🎉 Сегодня день рождения #{genitive_name(pets.first)}!"
    when 2
      "🎉 Сегодня день рождения у #{genitive_name(pets.first)} и #{genitive_name(pets.second)}!"
    else
      "🎉 Сегодня настоящий праздник!"
    end
  end

  def body
    case pets.size
    when 1
      "Исполняется #{age_label(pets.first)}. Самое время обнять именинника чуть крепче и угостить вкусняшкой 🐾"
    when 2
      "Настоящий двойной праздник. Самое время обнять именинников чуть крепче и угостить вкусняшками 🐾"
    else
      "День рождения отмечают #{names_sentence}. Самое время обнять именинников чуть крепче и угостить вкусняшками 🐾"
    end
  end

  def avatar_pets
    pets.size > 3 ? pets.first(2) : pets.first(3)
  end

  def overflow_count
    pets.size > 3 ? pets.size - 2 : 0
  end

  def multiple?
    pets.size > 1
  end

  private

  def age_label(pet)
    age = pet.age_on(date)
    "#{age} #{russian_plural(age, "год", "года", "лет")}"
  end

  def names_sentence
    names = pets.map(&:name)
    return names.first.to_s if names.one?
    return names.join(" и ") if names.size == 2

    "#{names[0...-1].join(', ')} и #{names.last}"
  end

  def russian_plural(number, one, few, many)
    return many if (11..14).cover?(number % 100)

    case number % 10
    when 1 then one
    when 2..4 then few
    else many
    end
  end

  def genitive_name(pet)
    name = pet.name.to_s.strip
    return name if name.blank?

    last = name[-1]&.downcase
    stem = name[0...-1]

    case last
    when "а"
      replacement = name[-2]&.downcase&.match?(/[гкхжчшщц]/) ? "и" : "ы"
      "#{stem}#{replacement}"
    when "я"
      "#{stem}и"
    when "ь"
      "#{stem}#{pet.sex == 1 ? 'и' : 'я'}"
    when "й"
      pet.sex == 0 ? "#{stem}я" : name
    when /[бвгджзклмнпрстфхцчшщ]/
      pet.sex == 0 ? "#{name}а" : name
    else
      name
    end
  end
end
