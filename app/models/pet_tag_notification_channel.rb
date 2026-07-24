class PetTagNotificationChannel < ApplicationRecord
  belongs_to :pet_tag
  belongs_to :notification_channel

  validate :channel_belongs_to_pet_owner

  private

  def channel_belongs_to_pet_owner
    return if pet_tag.blank? || notification_channel.blank?
    return if pet_tag.pet.user == notification_channel.user

    errors.add(:notification_channel, :invalid)
  end
end
