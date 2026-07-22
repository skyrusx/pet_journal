class PetTagsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_pet
  before_action :set_pet_tag, only: %i[show edit update]

  def show; end

  def create
    @pet_tag = @pet.build_pet_tag(pet_tag_params)

    if @pet_tag.save
      redirect_to pet_pet_tag_path(@pet), notice: "QR-профиль создан."
    else
      render :show, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @pet_tag.update(pet_tag_params)
      redirect_to pet_pet_tag_path(@pet), notice: "QR-профиль обновлен."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_pet
    @pet = current_user.pets.find(params[:pet_id])
  end

  def set_pet_tag
    @pet_tag = @pet.pet_tag || @pet.build_pet_tag
  end

  def pet_tag_params
    params.fetch(:pet_tag, {}).permit(:enabled, :public_message, :behavior_notes, :medical_notes, :contact_phone,
                                      :show_phone)
  end
end
