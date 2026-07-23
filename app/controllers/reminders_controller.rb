class RemindersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_pet
  before_action :set_reminder, only: %i[show edit update destroy complete pause resume]

  def index
    @active_reminders = @pet.reminders.status_active.order(:next_run_at)
    @completed_reminders = @pet.reminders.status_completed.order(last_completed_at: :desc).limit(10)
  end

  def show
    @deliveries = @reminder.notification_deliveries.includes(:notification_channel).order(created_at: :desc).limit(20)
  end

  def new
    @reminder = @pet.reminders.new(remind_at: 1.day.from_now.change(sec: 0))
  end

  def create
    @reminder = @pet.reminders.new(reminder_params)

    if @reminder.save
      redirect_to pet_reminders_path(@pet), notice: "Напоминание создано."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    @reminder.assign_attributes(reminder_params)
    @reminder.next_run_at = @reminder.remind_at
    @reminder.last_notified_at = nil

    if @reminder.save
      redirect_to pet_reminder_path(@pet, @reminder), notice: "Напоминание обновлено."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @reminder.destroy

    redirect_to pet_reminders_path(@pet), notice: "Напоминание удалено."
  end

  def complete
    create_event_from_reminder if params[:create_event] == "1"
    @reminder.complete!

    redirect_to pet_reminders_path(@pet), notice: "Напоминание выполнено."
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

  def reminder_params
    params.require(:reminder).permit(:title, :reminder_type, :remind_at, :repeat_rule, :note)
  end

  def create_event_from_reminder
    @pet.pet_events.create!(
      event_type: event_type_for(@reminder),
      title: @reminder.title,
      event_date: Date.current,
      description: ["Выполнено по напоминанию.", @reminder.note.presence].compact.join("\n\n")
    )
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
