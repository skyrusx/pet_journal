class PetPhotosController < ApplicationController
  before_action :authenticate_user!
  before_action :set_pet
  before_action :set_photo, only: %i[destroy primary crop]

  layout "workspace_new_design"

  def create
    PetPhotoManager.new(@pet).add!(photo_uploads)
    redirect_to edit_pet_path(@pet), notice: "Фотографии добавлены."
  rescue ActiveRecord::RecordInvalid, PetPhotoManager::Error => e
    redirect_to edit_pet_path(@pet), alert: error_message(e)
  end

  def destroy
    PetPhotoManager.new(@pet).remove!(@photo)
    redirect_to edit_pet_path(@pet), notice: "Фотография удалена."
  rescue ActiveRecord::RecordInvalid, PetPhotoManager::Error => e
    redirect_to edit_pet_path(@pet), alert: error_message(e)
  end

  def primary
    PetPhotoManager.new(@pet).make_primary!(@photo, crop_params)
    render json: { ok: true }
  rescue ActiveRecord::RecordInvalid, PetPhotoManager::Error => e
    render json: { error: error_message(e) }, status: :unprocessable_entity
  end

  def crop
    PetPhotoManager.new(@pet).update_crop!(@photo, crop_params)
    render json: { ok: true }
  rescue ActiveRecord::RecordInvalid, PetPhotoManager::Error => e
    render json: { error: error_message(e) }, status: :unprocessable_entity
  end

  def reorder
    PetPhotoManager.new(@pet).reorder!(params[:photo_ids])
    head :no_content
  rescue PetPhotoManager::Error => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  def set_pet
    @pet = current_user.pets.find(params[:pet_id])
  end

  def set_photo
    @photo = @pet.pet_photos.find(params[:id])
  end

  def photo_uploads
    Array(params[:images]).reject(&:blank?)
  end

  def crop_params
    params.require(:pet_photo).permit(:avatar_crop_x, :avatar_crop_y, :avatar_crop_width, :avatar_crop_height)
  end

  def error_message(error)
    return error.record.errors.full_messages.to_sentence if error.respond_to?(:record)

    error.message
  end
end
