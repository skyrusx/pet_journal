class PublicPetTagsController < ApplicationController
  layout "public"

  def show
    @pet_tag = PetTag.includes(pet: { photo_attachment: :blob }).find_by!(public_token: params[:token], enabled: true)
    @pet = @pet_tag.pet
    @pet_tag_scan = record_scan(@pet_tag)
  end

  def location
    @pet_tag = PetTag.find_by!(public_token: params[:token], enabled: true)
    @pet_tag_scan = @pet_tag.pet_tag_scans.find_by!(public_token: params[:scan_token])

    if @pet_tag_scan.update(location_params.merge(location_shared_at: Time.current))
      PetTagMailer.location_shared(@pet_tag_scan).deliver_now
      redirect_to public_pet_tag_path(@pet_tag.public_token), notice: "Геолокация отправлена владельцу."
    else
      redirect_to public_pet_tag_path(@pet_tag.public_token), alert: "Не удалось отправить геолокацию."
    end
  end

  private

  def record_scan(pet_tag)
    scan_from_session(pet_tag) || create_scan(pet_tag)
  end

  def scan_from_session(pet_tag)
    scan_state = session[:pet_tag_scans].to_h[pet_tag.public_token]
    return if scan_state.blank?
    return if Time.zone.parse(scan_state["created_at"]) < 5.minutes.ago

    pet_tag.pet_tag_scans.find_by(public_token: scan_state["scan_token"])
  rescue ArgumentError
    nil
  end

  def create_scan(pet_tag)
    scan = pet_tag.pet_tag_scans.create!(
      user_agent: request.user_agent,
      referrer: request.referrer
    )

    PetTagMailer.scan_notification(scan).deliver_now if pet_tag.notify_on_scan?

    session[:pet_tag_scans] = session[:pet_tag_scans].to_h.merge(
      pet_tag.public_token => {
        "scan_token" => scan.public_token,
        "created_at" => Time.current.iso8601
      }
    )

    scan
  end

  def location_params
    params.permit(:latitude, :longitude, :location_note)
  end
end
