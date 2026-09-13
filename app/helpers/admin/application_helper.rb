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
          },
          {
            label: "Питомцы",
            path: admin_pets_path,
            icon: :paw,
            active: controller_path == "admin/pets"
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

  def admin_last_seen_label(user)
    admin_activity_time_label(user.last_seen_at)
  end

  def admin_activity_time_label(time)
    return "Нет данных" if time.blank?

    zoned_time = time.in_time_zone(current_user.notifications_time_zone_name)
    today = Time.current.in_time_zone(current_user.notifications_time_zone_name).to_date

    case zoned_time.to_date
    when today
      "Сегодня, #{zoned_time.strftime('%H:%M')}"
    when today - 1.day
      "Вчера, #{zoned_time.strftime('%H:%M')}"
    else
      zoned_time.strftime("%d.%m.%Y %H:%M")
    end
  end

  def admin_pet_initial(pet)
    pet.name.to_s.first.to_s.upcase.presence || "P"
  end

  def admin_pet_species_label(pet)
    pet.species.presence || "Не указан"
  end

  def admin_pet_tag_label(pet)
    return "Нет" unless pet.pet_tag
    return "Потерян" if pet.pet_tag.status_lost?
    return "Найден" if pet.pet_tag.status_found?

    pet.pet_tag.enabled? ? "Активен" : "Выключен"
  end
end
