class PetEventsController < ApplicationController
  PAGE_SIZE = 25

  before_action :authenticate_user!
  before_action :set_pet, except: :index
  before_action :set_journal_pets
  before_action :set_pet_event, only: %i[show edit update destroy]

  layout "workspace_new_design"

  def index
    @event_type_filters = PetEvent::EVENT_TYPE_LABELS
    @selected_event_type = selected_event_type
    @selected_period = selected_period
    @selected_status = selected_status
    @selected_marker = selected_marker
    @query = params[:q].to_s.strip
    @selected_pet = selected_journal_pet
    @pet = @selected_pet

    base_scope = journal_events_scope
    @event_type_counts = base_scope.group(:event_type).count
    @total_events_count = base_scope.count
    @events_with_files_count = base_scope.joins(:files_attachments).distinct.count
    @events_with_follow_up_count = base_scope.where.not(next_action_at: nil).count
    @latest_event = base_scope.order(event_date: :desc, event_time: :desc, created_at: :desc).first

    filtered_scope = base_scope
    filtered_scope = filtered_scope.where(event_type: @selected_event_type) if @selected_event_type.present?
    filtered_scope = filter_by_period(filtered_scope)
    filtered_scope = filter_by_status(filtered_scope)
    filtered_scope = filter_by_marker(filtered_scope)
    filtered_scope = search_events(filtered_scope) if @query.present?

    @page = [params[:page].to_i, 1].max
    @events_limit = PAGE_SIZE * @page
    @matching_events_count = filtered_scope.distinct.count(:id)
    @has_more_events = @matching_events_count > @events_limit

    @pet_events = filtered_scope
                  .includes(:pet)
                  .with_attached_files
                  .order(event_date: :desc, event_time: :desc, created_at: :desc)
                  .limit(@events_limit)
  end

  def show; end

  def new
    @pet_event = @pet.pet_events.new(
      event_date: Date.current,
      event_time: Time.current,
      status: :completed,
      event_type: params[:type].presence_in(PetEvent.event_types.keys) || :note
    )
  end

  def create
    @pet_event = @pet.pet_events.new(pet_event_params)

    if @pet_event.save
      after_event_save
      redirect_to pet_pet_event_path(@pet, @pet_event), notice: "Событие добавлено."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @pet_event.update(pet_event_params)
      after_event_save
      redirect_to pet_pet_event_path(@pet, @pet_event), notice: "Событие обновлено."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @pet_event.destroy

    redirect_to journal_overview_path(pet_id: @pet.id), notice: "Событие удалено."
  end

  private

  def set_pet
    @pet = current_user.pets.find(params[:pet_id])
  end

  def set_journal_pets
    @journal_pets = current_user.pets.with_attached_photo.order(:name).to_a
  end

  def selected_journal_pet
    return if params[:pet_id].blank?

    current_user.pets.find_by(id: params[:pet_id])
  end

  def journal_events_scope
    scope = PetEvent.where(pet_id: @journal_pets.map(&:id))
    @selected_pet.present? ? scope.where(pet_id: @selected_pet.id) : scope
  end

  def set_pet_event
    @pet_event = @pet.pet_events.find(params[:id])
  end

  def pet_event_params
    params.require(:pet_event).permit(
      :event_type,
      :status,
      :title,
      :event_date,
      :event_time,
      :description,
      :weight_value,
      :weight_unit,
      :vaccine_name,
      :vaccine_batch,
      :valid_until,
      :clinic_name,
      :veterinarian_name,
      :medication_name,
      :dosage,
      :course_started_on,
      :course_ended_on,
      :next_action_at,
      :diagnosis,
      :recommendations,
      :symptoms,
      :severity,
      :symptom_started_on,
      :symptom_ended_on,
      files: []
    )
  end

  def selected_event_type
    return if params[:type].blank?

    params[:type] if PetEvent.event_types.key?(params[:type])
  end

  def selected_period
    params[:period].presence_in(%w[all month quarter year])
  end

  def selected_status
    return if params[:status].blank?

    params[:status] if PetEvent.statuses.key?(params[:status])
  end

  def selected_marker
    params[:marker].presence_in(%w[with_files follow_up])
  end

  def filter_by_period(scope)
    case @selected_period
    when "month"
      scope.where(event_date: 1.month.ago.to_date..Date.current)
    when "quarter"
      scope.where(event_date: 3.months.ago.to_date..Date.current)
    when "year"
      scope.where(event_date: 1.year.ago.to_date..Date.current)
    else
      scope
    end
  end

  def filter_by_status(scope)
    return scope if @selected_status.blank?

    scope.where(status: @selected_status)
  end

  def filter_by_marker(scope)
    case @selected_marker
    when "with_files"
      scope.joins(:files_attachments).distinct
    when "follow_up"
      scope.where.not(next_action_at: nil)
    else
      scope
    end
  end

  def search_events(scope)
    pattern = "%#{ActiveRecord::Base.sanitize_sql_like(@query)}%"
    scope.where(
      <<~SQL.squish,
        title ILIKE :query
        OR description ILIKE :query
        OR vaccine_name ILIKE :query
        OR vaccine_batch ILIKE :query
        OR clinic_name ILIKE :query
        OR veterinarian_name ILIKE :query
        OR medication_name ILIKE :query
        OR dosage ILIKE :query
        OR diagnosis ILIKE :query
        OR recommendations ILIKE :query
        OR symptoms ILIKE :query
      SQL
      query: pattern
    )
  end

  def after_event_save
    update_pet_weight if @pet_event.weight?
    create_follow_up_reminder if params[:create_follow_up_reminder] == "1" && @pet_event.next_action_at.present?
  end

  def update_pet_weight
    @pet.update!(weight: @pet_event.weight_value) if @pet_event.weight_value.present? && @pet_event.weight_unit == "kg"
  end

  def create_follow_up_reminder
    reminder = @pet.reminders.find_or_initialize_by(
      title: "Повторить: #{@pet_event.title.presence || @pet_event.event_type_label}",
      remind_at: @pet_event.next_action_at
    )
    reminder.assign_attributes(
      reminder_type: reminder_type_for_event,
      next_run_at: @pet_event.next_action_at,
      repeat_rule: :once,
      status: :active,
      note: "Создано из события журнала от #{@pet_event.event_date.strftime("%d.%m.%Y")}."
    )
    reminder.save!
  end

  def reminder_type_for_event
    {
      "vaccination" => :vaccination,
      "treatment" => :medication,
      "parasite_treatment" => :treatment,
      "visit" => :visit,
      "weight" => :weight
    }.fetch(@pet_event.event_type, :other)
  end
end
