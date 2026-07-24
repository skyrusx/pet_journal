module PetDocumentsHelper
  def document_type_options
    PetDocument.document_types.keys.map { |key| [I18n.t("pet_documents.types.#{key}"), key] }
  end

  def document_type_filters(pet, selected_type, selected_status, query)
    [["Все типы", nil, selected_type.blank?]] +
      PetDocument.document_types.keys.map do |type|
        [
          I18n.t("pet_documents.types.#{type}"),
          pet_pet_documents_path(pet, type:, status: selected_status, q: query.presence),
          selected_type == type
        ]
      end
  end

  def document_status_filters(pet, selected_status, selected_type, query)
    [
      ["Все", "all"],
      ["Актуальные", "active"],
      ["Скоро истекают", "expiring"],
      ["Просрочены", "expired"],
      ["Без срока", "no_expiry"]
    ].map do |label, status|
      [label, pet_pet_documents_path(pet, status:, type: selected_type.presence, q: query.presence), selected_status == status]
    end
  end

  def document_status_class(document)
    case document.status_tone
    when "danger" then "lost-pill"
    when "warning" then "signal-pill"
    when "success" then "status-pill success"
    else "status-pill muted"
    end
  end

  def document_file_label(document)
    count = document.files.count
    "#{count} #{russian_plural(count, "файл", "файла", "файлов")}"
  end
end
