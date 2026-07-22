class PetTagMailer < ApplicationMailer
  def scan_notification(pet_tag_scan)
    @pet_tag_scan = pet_tag_scan
    @pet_tag = pet_tag_scan.pet_tag
    @pet = @pet_tag.pet

    mail(to: @pet.user.email, subject: "PetTag: QR-профиль #{@pet.name} открыли")
  end

  def location_shared(pet_tag_scan)
    @pet_tag_scan = pet_tag_scan
    @pet_tag = pet_tag_scan.pet_tag
    @pet = @pet_tag.pet

    mail(to: @pet.user.email, subject: "PetTag: для #{@pet.name} отправили геолокацию")
  end
end
