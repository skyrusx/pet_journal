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

  def admin_pagination_pages(current_page, total_pages)
    return (1..total_pages).to_a if total_pages <= 5

    pages = [1, total_pages, current_page - 1, current_page, current_page + 1]
    pages.select { |page| page.between?(1, total_pages) }.uniq.sort
  end
end
