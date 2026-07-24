class PetDocumentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_pet
  before_action :set_document, only: %i[show edit update destroy destroy_file]

  def index
    @selected_type = params[:type].presence_in(PetDocument.document_types.keys)
    @selected_status = params[:status].presence_in(%w[all active expiring expired no_expiry]) || "all"
    @selected_scope = params[:scope].presence_in(%w[all with_files with_reminder]) || "all"
    @query = params[:q].to_s.strip
    @documents = filtered_documents.with_attached_files
    @event_file_events = legacy_event_file_events
    @document_counts = {
      total: @pet.pet_documents.count,
      expiring: @pet.pet_documents.expires_soon.count,
      expired: @pet.pet_documents.expired.count,
      no_expiry: @pet.pet_documents.where(expires_on: nil).count,
      with_files: @pet.pet_documents.joins(:files_attachments).distinct.count,
      with_reminder: @pet.pet_documents.where.not(reminder_id: nil).count,
      legacy_files: @event_file_events.sum { |event| event.files.count }
    }
    @highlight_documents = @pet.pet_documents.expired.limit(3).to_a + @pet.pet_documents.expires_soon.limit(3).to_a
  end

  def show; end

  def new
    @document = @pet.pet_documents.new(
      document_type: params[:type].presence_in(PetDocument.document_types.keys) || :other,
      issued_on: Date.current,
      expiry_reminder_days: 14
    )
  end

  def create
    @document = @pet.pet_documents.new(document_params)

    if @document.save
      sync_related_records
      redirect_to pet_pet_document_path(@pet, @document), notice: "Документ добавлен."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @document.update(document_params)
      sync_related_records
      redirect_to pet_pet_document_path(@pet, @document), notice: "Документ обновлен."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @document.destroy

    redirect_to pet_pet_documents_path(@pet), notice: "Документ удален."
  end

  def destroy_file
    attachment = @document.files.find(params[:attachment_id])
    attachment.purge

    redirect_to pet_pet_document_path(@pet, @document), notice: "Файл удален."
  end

  private

  def set_pet
    @pet = current_user.pets.find(params[:pet_id])
  end

  def set_document
    @document = @pet.pet_documents.find(params[:id])
  end

  def document_params
    params.require(:pet_document).permit(
      :document_type,
      :title,
      :issuer,
      :number,
      :issued_on,
      :expires_on,
      :expiry_reminder_days,
      :notes,
      files: []
    )
  end

  def sync_related_records
    @document.sync_journal_event! if params[:create_journal_event] == "1"
    @document.sync_expiry_reminder! if params[:create_expiry_reminder] == "1"
  end

  def filtered_documents
    scope = @pet.pet_documents.order(created_at: :desc)
    scope = scope.where(document_type: @selected_type) if @selected_type.present?
    scope = apply_status(scope)
    scope = apply_scope(scope)
    scope = apply_search(scope)
    scope
  end

  def apply_status(scope)
    case @selected_status
    when "active" then scope.where("expires_on IS NULL OR expires_on >= ?", Date.current)
    when "expiring" then scope.expires_soon
    when "expired" then scope.expired
    when "no_expiry" then scope.where(expires_on: nil)
    else scope
    end
  end

  def apply_search(scope)
    return scope if @query.blank?

    pattern = "%#{ActiveRecord::Base.sanitize_sql_like(@query)}%"
    scope.where(
      "title ILIKE :query OR issuer ILIKE :query OR number ILIKE :query OR notes ILIKE :query",
      query: pattern
    )
  end

  def apply_scope(scope)
    case @selected_scope
    when "with_files" then scope.joins(:files_attachments).distinct
    when "with_reminder" then scope.where.not(reminder_id: nil)
    else scope
    end
  end

  def legacy_event_file_events
    scope = @pet.pet_events.joins(:files_attachments).with_attached_files.distinct.order(event_date: :desc, created_at: :desc)
    return scope.limit(20).to_a if @query.blank?

    pattern = "%#{ActiveRecord::Base.sanitize_sql_like(@query)}%"
    scope.where("pet_events.title ILIKE :query OR pet_events.description ILIKE :query", query: pattern).limit(20).to_a
  end
end
