class WorkspaceSectionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_primary_pet

  layout "workspace_new_design"

  def journal
    return redirect_to pet_pet_events_path(@primary_pet) if @primary_pet

    configure_empty_section(
      key: "journal",
      title: "Журнал",
      subtitle: "История здоровья и ухода за питомцем в одном месте",
      empty_title: "Журнал пока пуст",
      empty_text: "Добавьте питомца, чтобы начать сохранять важные события, наблюдения и историю здоровья.",
      illustration: "petjournal/new_design/empty-journal.svg"
    )

    render :empty
  end

  def reminders
    return redirect_to pet_reminders_path(@primary_pet) if @primary_pet

    configure_empty_section(
      key: "reminders",
      title: "Напоминания",
      subtitle: "Важные дела по уходу — вовремя и без лишней суеты",
      empty_title: "Нет напоминаний",
      empty_text: "Добавьте питомца, чтобы настроить напоминания о прививках, лекарствах и ежедневной заботе.",
      illustration: "petjournal/new_design/empty-reminders.svg"
    )

    render :empty
  end

  def documents
    return redirect_to pet_pet_documents_path(@primary_pet) if @primary_pet

    configure_empty_section(
      key: "documents",
      title: "Документы",
      subtitle: "Паспорта, анализы, справки и другие важные документы питомца",
      empty_title: "Документы отсутствуют",
      empty_text: "Добавьте питомца, чтобы хранить его паспорт, результаты анализов, справки и другие документы в одном месте.",
      illustration: "petjournal/new_design/empty-documents.svg"
    )

    render :empty
  end

  def public_access
    return redirect_to pet_profile_shares_path(@primary_pet) if @primary_pet

    configure_empty_section(
      key: "public_access",
      title: "Публичный доступ",
      subtitle: "Безопасно делитесь выбранными данными питомца по отдельной ссылке",
      empty_title: "Сначала добавьте питомца",
      empty_text: "После создания профиля питомца вы сможете сформировать отдельную публичную ссылку и выбрать, какие данные по ней будут видны.",
      illustration: "petjournal/new_design/empty-public-access.svg"
    )

    render :empty
  end

  private

  def set_primary_pet
    @primary_pet = current_user.pets.order(created_at: :desc).first
  end

  def configure_empty_section(key:, title:, subtitle:, empty_title:, empty_text:, illustration:)
    @section_key = key
    @section_title = title
    @section_subtitle = subtitle
    @empty_title = empty_title
    @empty_text = empty_text
    @illustration = illustration
  end
end
