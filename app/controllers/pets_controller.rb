class PetsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_pet, only: %i[show edit update]

  def index
    @pets = current_user.pets.order(created_at: :desc)
  end

  def show; end

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
end
