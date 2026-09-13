module Admin::ApplicationHelper
  def admin_navigation_sections
    [
      {
        label: "Общее",
        items: [
          {
            label: "Обзор",
            path: admin_root_path,
            icon: :home,
            active: controller_path == "admin/dashboard"
          }
        ]
      },
      {
        label: "Управление",
        items: [
          {
            label: "Пользователи",
            path: admin_users_path,
            icon: :user,
            active: controller_path == "admin/users"
          }
        ]
      }
    ]
  end

  def admin_user_display_name(user)
    user.name.presence || user.email
  end

  def admin_user_initial(user)
    admin_user_display_name(user).to_s.first.to_s.upcase.presence || "P"
  end

  def admin_role_label(user)
    user.admin? ? "Администратор" : "Пользователь"
  end
end
