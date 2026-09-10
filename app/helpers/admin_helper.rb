module AdminHelper
  def admin_nav_link(label, path, icon:, active: false)
    link_to path,
            class: class_names("admin-nav-link", active: active),
            aria: { current: active ? "page" : nil } do
      safe_join([
        content_tag(:span, pj_icon(icon), class: "admin-nav-icon"),
        content_tag(:span, label)
      ])
    end
  end

  def admin_user_name(user)
    user.name.presence || user.email.to_s.split("@").first.presence || "Пользователь"
  end

  def admin_user_initial(user)
    admin_user_name(user).first.to_s.upcase.presence || "P"
  end

  def admin_greeting(time = Time.zone.now)
    case time.hour
    when 0..5 then "Доброй ночи"
    when 6..11 then "Доброе утро"
    when 12..17 then "Добрый день"
    else "Добрый вечер"
    end
  end

  def admin_date_label(date = Date.current)
    weekdays = %w[Воскресенье Понедельник Вторник Среда Четверг Пятница Суббота]
    months = %w[января февраля марта апреля мая июня июля августа сентября октября ноября декабря]

    "#{weekdays[date.wday]}, #{date.day} #{months[date.month - 1]} #{date.year}"
  end

  def admin_metric_change_label(metric)
    change_percent = metric[:change_percent]

    if change_percent.nil?
      return "—" if metric[:recent].zero?

      return "↑ +#{metric[:recent]}"
    end

    change_percent.negative? ? "↓ #{change_percent}%" : "↑ +#{change_percent}%"
  end

  def admin_metric_change_tone(metric)
    change_percent = metric[:change_percent]

    return metric[:recent].positive? ? "positive" : "neutral" if change_percent.nil?

    change_percent.negative? ? "negative" : "positive"
  end

  def admin_pagination_pages(current_page, total_pages)
    return (1..total_pages).to_a if total_pages <= 5

    pages = [1, total_pages, current_page - 1, current_page, current_page + 1]
    pages.select { |page| page.between?(1, total_pages) }.uniq.sort
  end
end
