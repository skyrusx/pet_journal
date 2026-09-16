module PetGalleryHelper
  def pet_avatar_tag(pet, class_name:, alt: "", loading: "lazy")
    gallery_photo = pet.primary_photo

    if gallery_photo&.image&.attached?
      classes = class_names(class_name, "pj-pet-avatar-frame", "has-custom-crop": gallery_photo.avatar_crop?)
      image = gallery_photo.image.variant(resize_to_limit: [900, 900])
      crop_data = pet_avatar_crop_data(gallery_photo)

      content_tag(:span, class: classes) do
        image_tag(
          image,
          alt: alt,
          loading: loading,
          class: "pj-pet-avatar-frame__image is-cover",
          data: crop_data
        )
      end
    elsif pet.photo.attached?
      content_tag(:span, class: class_names(class_name, "pj-pet-avatar-frame")) do
        image_tag pet.photo, alt: alt, loading: loading, class: "pj-pet-avatar-frame__image is-cover"
      end
    else
      content_tag(:span, class: class_names(class_name, "pj-pet-avatar-frame", "is-empty")) do
        content_tag(:span, pet.name.to_s.first.to_s.upcase.presence || "P")
      end
    end
  end

  def pet_gallery_photo_count_label(count)
    "#{count} #{russian_plural(count, "фотография", "фотографии", "фотографий")}"
  end

  private

  def pet_avatar_crop_data(photo)
    return {} unless photo.avatar_crop?

    {
      pet_avatar_crop: true,
      crop_x: photo.avatar_crop_x,
      crop_y: photo.avatar_crop_y,
      crop_width: photo.avatar_crop_width,
      crop_height: photo.avatar_crop_height
    }
  end
end
