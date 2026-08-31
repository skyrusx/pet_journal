class PublicPetProfileSharesController < ApplicationController
  require "ipaddr"

  layout "public"
  before_action :prevent_public_indexing

  def show
    @share = PetProfileShare.includes(pet: [{ photo_attachment: :blob }, :user, :pet_tag]).find_by!(public_token: params[:token])
    raise ActiveRecord::RecordNotFound unless @share.active?

    # Public human contact disclosure is fail-closed until a dedicated
    # dissemination-consent flow is implemented. Keep this guard even for
    # legacy rows that still contain an old true flag before migrations run.
    @share.show_owner_contact = false
    @pet = @share.pet
    @pet.pet_tag.show_phone = false if @pet.pet_tag.present?
    record_view(@share)
    load_shared_sections
  end

  private

  def prevent_public_indexing
    response.set_header("X-Robots-Tag", "noindex, nofollow")
    expires_now
  end

  def record_view(share)
    return if recent_view_from_session?(share)

    share.pet_profile_share_views.create!(
      public_token: share.public_token,
      user_agent: request.user_agent.to_s.truncate(500),
      referrer: request.referrer.to_s.truncate(500),
      ip_address: anonymized_ip(request.remote_ip)
    )
    share.update_column(:last_viewed_at, Time.current)
    session[:profile_share_views] = session[:profile_share_views].to_h.merge(
      share.public_token => Time.current.iso8601
    )
  end

  def recent_view_from_session?(share)
    viewed_at = session[:profile_share_views].to_h[share.public_token]
    return false if viewed_at.blank?

    Time.zone.parse(viewed_at) >= 15.minutes.ago
  rescue ArgumentError
    false
  end

  def anonymized_ip(value)
    ip = IPAddr.new(value)

    if ip.ipv4?
      octets = ip.to_s.split(".")
      "#{octets[0]}.#{octets[1]}.#{octets[2]}.0"
    else
      "#{ip.mask(64)}"
    end
  rescue IPAddr::InvalidAddressError
    nil
  end

  def load_shared_sections
    limit = @share.detail_full? ? 50 : 5

    @events = @share.show_journal? ? @pet.pet_events.with_attached_files.order(event_date: :desc, created_at: :desc).limit(limit) : PetEvent.none
    @documents = @share.show_documents? ? @pet.pet_documents.with_attached_files.order(created_at: :desc).limit(limit) : PetDocument.none
    @reminders = @share.show_reminders? ? @pet.reminders.status_active.order(:next_run_at).limit(limit) : Reminder.none
    @pet_tag = @share.show_pet_tag? ? @pet.pet_tag : nil
  end
end
