module PetGalleryHelper
  def pet_avatar_tag(pet, class_name:, alt: "", loading: "lazy")
    gallery_photo = pet.primary_photo

    if gallery_photo&.image&.attached?
      classes = class_names(class_name, "pj-pet-avatar-frame", "has-custom-crop": gallery_photo.avatar_crop?)
      image = gallery_photo.image.variant(resize_to_limit: [900, 900])

      content_tag(:span, class: classes) do
        image_tag(
          image,
          alt: alt,
          loading: loading,
          class: class_names("pj-pet-avatar-frame__image", "is-cover": !gallery_photo.avatar_crop?),
          style: pet_avatar_crop_style(gallery_photo)
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

  def pet_avatar_crop_style(photo)
    return if !photo.avatar_crop? || photo.avatar_crop_width.to_f.zero? || photo.avatar_crop_height.to_f.zero?

    width = 100.0 / photo.avatar_crop_width.to_f
    left = -(photo.avatar_crop_x.to_f / photo.avatar_crop_width.to_f) * 100.0
    top = -(photo.avatar_crop_y.to_f / photo.avatar_crop_height.to_f) * 100.0

    "width: #{width.round(5)}%; left: #{left.round(5)}%; top: #{top.round(5)}%;"
  end
end
