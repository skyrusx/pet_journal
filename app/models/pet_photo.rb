class PetPhoto < ApplicationRecord
  MAX_PHOTOS_PER_PET = 20
  MAX_FILE_SIZE = 5.megabytes
  ACCEPTED_CONTENT_TYPES = %w[image/jpeg image/png image/webp].freeze

  belongs_to :pet
  has_one_attached :image

  scope :ordered, -> { order(:position, :id) }

  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validate :image_is_attached
  validate :image_is_supported
  validate :gallery_has_capacity, on: :create
  validate :avatar_crop_is_valid

  def avatar_crop?
    avatar_crop_values.all?(&:present?)
  end

  private

  def image_is_attached
    errors.add(:image, "нужно выбрать") unless image.attached?
  end

  def image_is_supported
    return unless image.attached?

    unless ACCEPTED_CONTENT_TYPES.include?(image.blob.content_type)
      errors.add(:image, "должно быть JPEG, PNG или WebP")
    end

    return unless image.blob.byte_size > MAX_FILE_SIZE

    errors.add(:image, "не должно быть больше 5 МБ")
  end

  def gallery_has_capacity
    return if pet.blank?
    return if pet.pet_photos.where.not(id: id).count < MAX_PHOTOS_PER_PET

    errors.add(:base, "Можно загрузить не больше #{MAX_PHOTOS_PER_PET} фотографий питомца")
  end

  def avatar_crop_is_valid
    values = avatar_crop_values
    return if values.all?(&:nil?)

    unless values.all?(&:present?)
      errors.add(:base, "Область аватара задана не полностью")
      return
    end

    x, y, width, height = values.map(&:to_f)
    valid = x.between?(0.0, 1.0) && y.between?(0.0, 1.0) &&
            width.positive? && height.positive? &&
            width <= 1.0 && height <= 1.0 &&
            (x + width) <= 1.0001 && (y + height) <= 1.0001

    errors.add(:base, "Область аватара выходит за границы фотографии") unless valid
  end

  def avatar_crop_values
    [avatar_crop_x, avatar_crop_y, avatar_crop_width, avatar_crop_height]
  end
end
