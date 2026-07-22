class PublicPetTagsController < ApplicationController
  layout "public"

  def show
    @pet_tag = PetTag.includes(pet: { photo_attachment: :blob }).find_by!(public_token: params[:token], enabled: true)
    @pet = @pet_tag.pet
  end
end
