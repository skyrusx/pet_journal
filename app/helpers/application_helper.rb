module ApplicationHelper
  def russian_plural(number, one, few, many)
    return many if (11..14).cover?(number % 100)

    case number % 10
    when 1 then one
    when 2..4 then few
    else many
    end
  end
end
