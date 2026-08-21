class RemindersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_pet
  before_action :set_reminder, only: %i[show edit update destroy complete pause resume snooze]
  before_action :set_notification_channels, only: %i[new create edit update show]
  before_action :set_reminder_pets, only: %i[index new create edit update]

  layout "workspace_new_design"

  def index
    @selected_status = params[:status].presence_in(%w[all active today overdue paused completed]) || "active"
    @selected_type = params[:type].presence_in(Reminder.reminder_types.keys)
    @query = params[:q].to_s.strip
    @reminders = filtered_reminders
    @total_count = @pet.reminders.count
    @active_count = @pet.reminders.status_active.count
    @today_count = @pet.reminders.status_active.where(next_run_at: Time.current.beginning_of_day..Time.current.end_of_day).count
    @overdue_count = @pet.reminders.overdue.count
    @paused_count = @pet.reminders.status_paused.count
    @completed_count = @pet.reminders.status_completed.count
    @next_reminder = @pet.reminders.status_active.order(:next_run_at).first
    @completed_reminders = @pet.reminders.status_completed.order(last_completed_at: :desc).limit(10)
  end

  def show
    @deliveries = @reminder.notification_deliveries.includes(:notification_channel).order(created_at: :desc).limit(20)
    @completions = @reminder.reminder_completions.includes(:pet_event).order(completed_at: :desc).limit(20)
  end

  def new
    @reminder = @pet.reminders.new(default_reminder_attributes.merge(reminder_prefill_params))
  end

  def create
    target_pet = selected_reminder_pet
    @reminder = target_pet.reminders.new(reminder_params)

    if @reminder.save
      sync_notification_channels
      redirect_to pet_reminders_path(target_pet), notice: "Напоминание создано."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    target_pet = selected_reminder_pet
    @reminder.assign_attributes(reminder_params)
    @reminder.pet = target_pet
    @reminder.next_run_at = @reminder.remind_at
    @reminder.last_notified_at = nil

    if @reminder.save
      sync_notification_channels
      redirect_to pet_reminder_path(target_pet, @reminder), notice: "Напоминание обновлено."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @reminder.destroy

    redirect_to pet_reminders_path(@pet), notice: "Напоминание удалено."
  end

  def complete
    event = create_event_from_reminder if params[:create_event] == "1"
    @reminder.complete!(pet_event: event, note: params[:completion_note])

    redirect_to pet_reminders_path(@pet), notice: "Напоминание выполнено."
  end

  def snooze
    @reminder.snooze_until!(snooze_time)

    redirect_to pet_reminders_path(@pet), notice: "Напоминание отложено."
  rescue ArgumentError
    redirect_to pet_reminders_path(@pet), alert: "Не удалось определить время отложенного напоминания."
  end

  def pause
    @reminder.update!(status: :paused)

    redirect_to pet_reminders_path(@pet), notice: "Напоминание приостановлено."
  end

  def resume
    @reminder.update!(status: :active, next_run_at: [@reminder.next_run_at, Time.current].max, last_notified_at: nil)

    redirect_to pet_reminders_path(@pet), notice: "Напоминание включено."
  end

  private

  def set_pet
    @pet = current_user.pets.find(params[:pet_id])
  end

  def set_reminder
    @reminder = @pet.reminders.find(params[:id])
  end

  def set_notification_channels
    @notification_channels = current_user.notification_channels.enabled.order(:channel_type, :created_at)
  end

  def set_reminder_pets
    @reminder_pets = current_user.pets.with_attached_photo.order(:name).to_a
  end

  def selected_reminder_pet
    pet_id = params.dig(:reminder, :pet_id).presence
    return @pet if pet_id.blank?

    current_user.pets.find(pet_id)
  end

  def reminder_params
    params.require(:reminder).permit(:title, :reminder_type, :remind_at, :repeat_rule, :repeat_interval, :repeat_unit, :note)
  end

  def default_reminder_attributes
    {
      reminder_type: params[:type].presence_in(Reminder.reminder_types.keys) || :other,
      remind_at: 1.day.from_now.change(sec: 0),
      repeat_rule: :once
    }
  end

  def reminder_prefill_params
    return {} unless params[:reminder].present?

    attributes = params.require(:reminder).permit(
      :title,
      :reminder_type,
      :remind_at,
      :repeat_rule,
      :repeat_interval,
      :repeat_unit,
      :note
    ).to_h.compact_blank

    attributes.delete("reminder_type") unless attributes["reminder_type"].in?(Reminder.reminder_types.keys)
    attributes.delete("repeat_rule") unless attributes["repeat_rule"].blank? || attributes["repeat_rule"].in?(Reminder.repeat_rules.keys)
    attributes.delete("repeat_unit") unless attributes["repeat_unit"].blank? || attributes["repeat_unit"].in?(Reminder.repeat_units.keys)
    attributes
  end

  def sync_notification_channels
    channel_ids = Array(params.dig(:reminder, :notification_channel_ids)).reject(&:blank?)
    channels = current_user.notification_channels.enabled.where(id: channel_ids)

    @reminder.notification_channels = channels
  end

  def create_event_from_reminder
    @pet.pet_events.create!(
      event_type: event_type_for(@reminder),
      title: @reminder.title,
      event_date: Date.current,
      description: ["Выполнено по напоминанию.", @reminder.note.presence].compact.join("\n\n")
    )
  end

  def filtered_reminders
    scope = @pet.reminders.order(:next_run_at)
    scope = scope.where(reminder_type: @selected_type) if @selected_type.present?

    if @query.present?
      escaped_query = ActiveRecord::Base.sanitize_sql_like(@query)
      pattern = "%#{escaped_query}%"
      scope = scope.where("reminders.title ILIKE :pattern OR reminders.note ILIKE :pattern", pattern: pattern)
    end

    case @selected_status
    when "all" then scope
    when "today" then scope.status_active.where(next_run_at: Time.current.beginning_of_day..Time.current.end_of_day)
    when "overdue" then scope.overdue
    when "paused" then scope.status_paused
    when "completed" then scope.status_completed.order(last_completed_at: :desc)
    else scope.status_active
    end
  end

  def snooze_time
    case params[:preset]
    when "hour" then 1.hour.from_now
    when "tomorrow" then 1.day.from_now.change(hour: 9, min: 0, sec: 0)
    when "week" then 1.week.from_now
    when "custom" then Time.zone.parse(params.require(:snooze_until))
    else raise ArgumentError
    end
  end

  def event_type_for(reminder)
    {
      "medication" => "treatment",
      "vaccination" => "vaccination",
      "treatment" => "treatment",
      "visit" => "visit",
      "weight" => "weight"
    }.fetch(reminder.reminder_type, "note")
  end
end
