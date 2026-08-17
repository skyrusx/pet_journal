module ApplicationHelper
  def russian_plural(number, one, few, many)
    return many if (11..14).cover?(number % 100)

    case number % 10
    when 1 then one
    when 2..4 then few
    else many
    end
  end

  def app_nav_link(label, path, active: false, **options)
    classes = class_names("app-nav-link", active: active)
    link_to(label, path, options.merge(class: classes))
  end

  def pet_nav_items(pet)
    [
      ["Обзор", pet_path(pet), controller_name == "pets" && action_name == "show"],
      ["Журнал", pet_pet_events_path(pet), controller_name == "pet_events"],
      ["Напоминания", pet_reminders_path(pet), controller_name == "reminders"],
      ["Документы", pet_pet_documents_path(pet), controller_name == "pet_documents"],
      ["Жетон", pet_pet_tag_path(pet), controller_name == "pet_tags"],
      ["Доступ", pet_profile_shares_path(pet), controller_name == "pet_profile_shares"],
      ["Данные", edit_pet_path(pet), controller_name == "pets" && action_name == "edit"]
    ]
  end
end
