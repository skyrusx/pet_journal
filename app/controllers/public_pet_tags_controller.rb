class PublicPetTagsController < ApplicationController
  layout "public"
  before_action :prevent_public_indexing

  def show
    @pet_tag = PetTag.includes(:user_consents, pet: { photo_attachment: :blob }).find_by(public_token: params[:token])

    unless @pet_tag&.enabled?
      render :unavailable, status: :not_found
      return
    end

    @pet = @pet_tag.pet
    @pet_tag_scan = record_scan(@pet_tag)
  end

  def location
    @pet_tag = PetTag.find_by(public_token: params[:token])

    unless @pet_tag&.enabled?
      render :unavailable, status: :not_found
      return
    end

    @pet_tag_scan = @pet_tag.pet_tag_scans.find_by(public_token: params[:scan_token])
    unless @pet_tag_scan && scan_belongs_to_session?(@pet_tag, @pet_tag_scan)
      render :unavailable, status: :not_found
      return
    end

    if @pet_tag_scan.location_shared?
      redirect_to public_pet_tag_path(@pet_tag.public_token), alert: "Сообщение уже отправлено владельцу."
      return
    end

    unless finder_personal_data_consent?
      redirect_to public_pet_tag_path(@pet_tag.public_token, anchor: "found-form"),
                  alert: "Чтобы отправить данные владельцу, подтвердите согласие на их обработку."
      return
    end

    consent_metadata = {
      finder_consent_version: LegalDocuments.version(:pet_tag_finder_consent),
      finder_privacy_policy_version: LegalDocuments.version(:privacy_policy),
      finder_consented_at: Time.current
    }

    if @pet_tag_scan.update(location_params.merge(consent_metadata).merge(scan_status: :found_reported, location_shared_at: Time.current, found_reported_at: Time.current))
      @pet_tag.mark_found!(message: @pet_tag_scan.finder_message) if @pet_tag.lost_mode_enabled?
      PetTagScanNotifier.notify(@pet_tag_scan, event: :found)
      redirect_to public_pet_tag_path(@pet_tag.public_token), notice: "Геолокация отправлена владельцу."
    else
      redirect_to public_pet_tag_path(@pet_tag.public_token), alert: "Не удалось отправить геолокацию."
    end
  end

  private

  def prevent_public_indexing
    response.set_header("X-Robots-Tag", "noindex, nofollow")
    expires_now
  end

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
    scan = pet_tag.pet_tag_scans.create!

    PetTagScanNotifier.notify(scan, event: :scan) if pet_tag.notify_on_scan?

    session[:pet_tag_scans] = session[:pet_tag_scans].to_h.merge(
      pet_tag.public_token => {
        "scan_token" => scan.public_token,
        "created_at" => Time.current.iso8601
      }
    )

    scan
  end

  def location_params
    params.permit(:latitude, :longitude, :location_note, :finder_name, :finder_contact, :finder_message)
  end

  def finder_personal_data_consent?
    params[:finder_personal_data_consent].to_s == "1"
  end

  def scan_belongs_to_session?(pet_tag, scan)
    session[:pet_tag_scans].to_h.dig(pet_tag.public_token, "scan_token") == scan.public_token
  end
end
