class PetsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_pet, only: %i[show edit update]

  def index
    @pets = current_user.pets.with_attached_photo.order(created_at: :desc).to_a
    @latest_events_by_pet_id = latest_events_by_pet_id(@pets)
  end

  def show
    @recent_events = @pet.pet_events.with_attached_files.order(event_date: :desc, created_at: :desc).limit(5)
    @latest_events_by_type = latest_events_by_type(@pet)
    @attached_files_count = @pet.pet_events.joins(:files_attachments).count
    @pet_tag = @pet.pet_tag
    @latest_pet_tag_scan = @pet_tag&.pet_tag_scans&.order(created_at: :desc)&.first
    @pet_tag_scan_count = @pet_tag&.pet_tag_scans&.count.to_i
  end

  def new
    @pet = current_user.pets.new
  end

  def create
    @pet = current_user.pets.new(pet_params)

    if @pet.save
      redirect_to @pet, notice: "Питомец добавлен."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @pet.update(pet_params)
      redirect_to @pet, notice: "Данные питомца обновлены."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_pet
    @pet = current_user.pets.find(params[:id])
  end

  def pet_params
    params.require(:pet).permit(:name, :species, :breed, :sex, :birth_date, :weight, :color, :chip_number,
                                :passport_number, :neutered, :notes, :photo)
  end

  def latest_events_by_pet_id(pets)
    pet_ids = pets.map(&:id)
    return {} if pet_ids.empty?

    PetEvent.where(pet_id: pet_ids)
            .order(event_date: :desc, created_at: :desc)
            .to_a
            .group_by(&:pet_id)
            .transform_values(&:first)
  end

  def latest_events_by_type(pet)
    pet.pet_events
       .order(event_date: :desc, created_at: :desc)
       .to_a
       .group_by(&:event_type)
       .transform_values(&:first)
  end
end
