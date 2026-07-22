class PetEventsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_pet
  before_action :set_pet_event, only: %i[show edit update destroy]

  def index
    @event_type_filters = PetEvent::EVENT_TYPE_LABELS
    @selected_event_type = selected_event_type
    @event_type_counts = @pet.pet_events.group(:event_type).count

    @pet_events = @pet.pet_events.with_attached_files.order(event_date: :desc, created_at: :desc)
    @pet_events = @pet_events.where(event_type: @selected_event_type) if @selected_event_type.present?
  end

  def show; end

  def new
    @pet_event = @pet.pet_events.new(event_date: Date.current)
  end

  def create
    @pet_event = @pet.pet_events.new(pet_event_params)

    if @pet_event.save
      redirect_to pet_pet_event_path(@pet, @pet_event), notice: "Событие добавлено."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @pet_event.update(pet_event_params)
      redirect_to pet_pet_event_path(@pet, @pet_event), notice: "Событие обновлено."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @pet_event.destroy

    redirect_to pet_pet_events_path(@pet), notice: "Событие удалено."
  end

  private

  def set_pet
    @pet = current_user.pets.find(params[:pet_id])
  end

  def set_pet_event
    @pet_event = @pet.pet_events.find(params[:id])
  end

  def pet_event_params
    params.require(:pet_event).permit(:event_type, :title, :event_date, :description, files: [])
  end

  def selected_event_type
    return if params[:type].blank?

    params[:type] if PetEvent.event_types.key?(params[:type])
  end
end
