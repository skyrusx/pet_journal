class PetsController < ApplicationController
  before_action :authenticate_user!

  def index
    @pets = current_user.pets.order(created_at: :desc)
  end

  def show
    @pet = current_user.pets.find(params[:id])
  end

  def new
    @pet = current_user.pets.new
  end

  def create
    @pet = current_user.pets.new(pet_params)

    if @pet.save
      redirect_to @pet, notice: "Питомец успешно добавлен."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def pet_params
    params.require(:pet).permit(:name, :species, :breed, :sex, :birth_date, :weight, :color, :chip_number,
                                :passport_number, :neutered, :notes, :photo)
  end
end
