class PetPhotoManager
  class Error < StandardError; end

  CROP_KEYS = %i[avatar_crop_x avatar_crop_y avatar_crop_width avatar_crop_height].freeze

  def initialize(pet)
    @pet = pet
  end

  def add!(uploads)
    uploads = Array(uploads).reject(&:blank?)
    return [] if uploads.empty?

    existing_count = @pet.pet_photos.count
    if existing_count + uploads.size > PetPhoto::MAX_PHOTOS_PER_PET
      raise Error, "Можно загрузить не больше #{PetPhoto::MAX_PHOTOS_PER_PET} фотографий питомца"
    end

    created = []
    start_position = @pet.pet_photos.maximum(:position) || -1
    make_first_primary = existing_count.zero?

    PetPhoto.transaction do
      uploads.each_with_index do |upload, index|
        photo = @pet.pet_photos.build(
          position: start_position + index + 1,
          is_primary: make_first_primary && index.zero?
        )
        photo.image.attach(upload)
        photo.save!
        created << photo
      end

      sync_legacy_attachment! if make_first_primary
    end

    created
  end

  def make_primary!(photo, crop_attributes = {})
    ensure_owned!(photo)

    PetPhoto.transaction do
      current_primary = @pet.pet_photos.find_by(is_primary: true)
      current_position = current_primary&.position || 0
      selected_position = photo.position

      if current_primary && current_primary.id != photo.id
        current_primary.update!(is_primary: false, position: selected_position)
      end

      photo.update!(normalized_crop(crop_attributes).merge(is_primary: true, position: current_position))
      normalize_profile_and_gallery_positions!
      sync_legacy_attachment!
    end

    photo
  end

  def update_crop!(photo, crop_attributes)
    ensure_owned!(photo)
    photo.update!(normalized_crop(crop_attributes))
    photo
  end

  def reorder!(photo_ids)
    ids = Array(photo_ids).map(&:to_i)
    current_ids = @pet.pet_photos.where(is_primary: false).ordered.pluck(:id)

    unless ids.length == current_ids.length && ids.uniq.length == ids.length && ids.sort == current_ids.sort
      raise Error, "Состав галереи изменился. Обновите страницу и повторите сортировку."
    end

    PetPhoto.transaction do
      @pet.pet_photos.where(is_primary: true).update_all(position: 0, updated_at: Time.current)

      ids.each_with_index do |id, index|
        @pet.pet_photos.where(id: id).update_all(position: index + 1, updated_at: Time.current)
      end
    end
  end

  def remove!(photo)
    ensure_owned!(photo)

    PetPhoto.transaction do
      if photo.is_primary?
        replacement = @pet.pet_photos.ordered.where.not(id: photo.id).first
        photo.update_column(:is_primary, false)
        replacement&.update!(is_primary: true)
        sync_legacy_attachment!
      end

      photo.destroy!
      compact_positions!
    end
  end

  private

  def ensure_owned!(photo)
    return if photo.pet_id == @pet.id

    raise Error, "Фотография не принадлежит этому питомцу"
  end

  def normalized_crop(attributes)
    source = attributes.to_h.symbolize_keys.slice(*CROP_KEYS)
    return {} if source.empty?

    CROP_KEYS.index_with do |key|
      value = source[key]
      value.present? ? Float(value) : nil
    rescue ArgumentError, TypeError
      nil
    end
  end

  def normalize_profile_and_gallery_positions!
    primary = @pet.pet_photos.find_by(is_primary: true)
    primary&.update_columns(position: 0, updated_at: Time.current) unless primary&.position == 0

    @pet.pet_photos.where(is_primary: false).ordered.each_with_index do |photo, index|
      position = index + 1
      next if photo.position == position

      photo.update_columns(position: position, updated_at: Time.current)
    end
  end

  def compact_positions!
    primary = @pet.pet_photos.find_by(is_primary: true)
    if primary
      primary.update_columns(position: 0, updated_at: Time.current) unless primary.position == 0
      @pet.pet_photos.where(is_primary: false).ordered.each_with_index do |photo, index|
        position = index + 1
        next if photo.position == position

        photo.update_columns(position: position, updated_at: Time.current)
      end
    else
      @pet.pet_photos.ordered.each_with_index do |photo, position|
        next if photo.position == position

        photo.update_columns(position: position, updated_at: Time.current)
      end
    end
  end

  # The old Pet#photo attachment remains during the transition because several
  # existing screens still read it. Point its attachment row at the current
  # primary blob without purging the previous gallery blob.
  def sync_legacy_attachment!
    primary = @pet.pet_photos.find_by(is_primary: true)
    legacy = ActiveStorage::Attachment.find_by(
      record_type: "Pet",
      record_id: @pet.id,
      name: "photo"
    )

    unless primary&.image&.attached?
      legacy&.delete
      return
    end

    if legacy
      legacy.update!(blob_id: primary.image.blob_id)
    else
      ActiveStorage::Attachment.create!(
        name: "photo",
        record_type: "Pet",
        record_id: @pet.id,
        blob_id: primary.image.blob_id
      )
    end
  end
end
