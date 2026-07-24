class PublicPetProfileSharesController < ApplicationController
  layout "public"

  def show
    @share = PetProfileShare.includes(pet: [{ photo_attachment: :blob }, :user, :pet_tag]).find_by!(public_token: params[:token])
    raise ActiveRecord::RecordNotFound unless @share.active?

    @pet = @share.pet
    record_view(@share)
    load_shared_sections
  end

  private

  def record_view(share)
    share.pet_profile_share_views.create!(
      public_token: share.public_token,
      user_agent: request.user_agent,
      referrer: request.referrer,
      ip_address: request.remote_ip
    )
    share.update_column(:last_viewed_at, Time.current)
  end

  def load_shared_sections
    limit = @share.detail_full? ? 50 : 5

    @events = @share.show_journal? ? @pet.pet_events.with_attached_files.order(event_date: :desc, created_at: :desc).limit(limit) : PetEvent.none
    @documents = @share.show_documents? ? @pet.pet_documents.with_attached_files.order(created_at: :desc).limit(limit) : PetDocument.none
    @reminders = @share.show_reminders? ? @pet.reminders.status_active.order(:next_run_at).limit(limit) : Reminder.none
    @pet_tag = @share.show_pet_tag? ? @pet.pet_tag : nil
  end
end
