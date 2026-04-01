class PetEventsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_pet
  before_action :set_pet_event, only: %i[show edit update destroy]

  def index
    @pet_events = @pet.pet_events.order(event_date: :desc, created_at: :desc)
  end

  def show; end

  def new
    @pet_event = @pet.pet_events.new
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
end
