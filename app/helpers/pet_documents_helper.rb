module PetDocumentsHelper
  def document_type_options
    PetDocument.document_types.keys.map { |key| [I18n.t("pet_documents.types.#{key}"), key] }
  end

  def document_type_filters(pet, selected_type, selected_status, query)
    [["Все типы", nil, selected_type.blank?]] +
      PetDocument.document_types.keys.map do |type|
        [
          I18n.t("pet_documents.types.#{type}"),
          pet_pet_documents_path(pet, document_filter_params.merge(type:).compact_blank),
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
      [label, pet_pet_documents_path(pet, document_filter_params.merge(status:).compact_blank), selected_status == status]
    end
  end

  def document_scope_filters(pet, selected_scope)
    [
      ["Все документы", "all"],
      ["С файлами", "with_files"],
      ["С напоминанием", "with_reminder"]
    ].map do |label, scope|
      [label, pet_pet_documents_path(pet, document_filter_params.merge(scope:).compact_blank), selected_scope == scope]
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

  def document_filter_summary(selected_type, selected_status, selected_scope, query)
    filters = []
    filters << I18n.t("pet_documents.types.#{selected_type}") if selected_type.present?
    filters << {
      "active" => "актуальные",
      "expiring" => "скоро истекают",
      "expired" => "просрочены",
      "no_expiry" => "без срока"
    }[selected_status]
    filters << { "with_files" => "с файлами", "with_reminder" => "с напоминанием" }[selected_scope]
    filters << "поиск: #{query}" if query.present?

    filters.compact.presence&.join(" · ") || "Показаны все документы"
  end

  def quick_document_actions(pet)
    [
      ["Ветпаспорт", new_pet_pet_document_path(pet, type: :passport)],
      ["Прививка", new_pet_pet_document_path(pet, type: :vaccination)],
      ["Анализы", new_pet_pet_document_path(pet, type: :lab_result)],
      ["Назначение", new_pet_pet_document_path(pet, type: :prescription)],
      ["Справка", new_pet_pet_document_path(pet, type: :certificate)]
    ]
  end

  private

  def document_filter_params
    {
      q: params[:q].presence,
      type: params[:type].presence,
      status: params[:status].presence,
      scope: params[:scope].presence
    }
  end
end
