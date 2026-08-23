class PagesController < ApplicationController
  def index
    unless user_signed_in?
      render :new_design, layout: "new_design"
      return
    end

    @pets = current_user.pets
                        .with_attached_photo
                        .includes(:reminders, pet_tag: :pet_tag_scans)
                        .order(created_at: :desc)
                        .to_a
    pet_ids = @pets.map(&:id)

    @latest_events_by_pet_id = latest_events_by_pet_id(@pets)
    @next_reminders = current_user.reminders.status_active.includes(:pet).order(:next_run_at).limit(5)
    @overdue_reminders_count = current_user.reminders.overdue.count
    @today_reminders_count = current_user.reminders.status_active.where(next_run_at: Time.current.beginning_of_day..Time.current.end_of_day).count
    @recent_events = PetEvent.includes(:pet).where(pet_id: pet_ids).order(event_date: :desc, created_at: :desc).limit(5)

    expiring_documents = PetDocument.includes(:pet).where(pet_id: pet_ids).expires_soon
    @expiring_documents_count = expiring_documents.count
    @expiring_documents = expiring_documents.limit(5)

    @pet_tag_scans_count = PetTagScan.joins(pet_tag: :pet).where(pets: { user_id: current_user.id }).count
    @profile_share_views_count = PetProfileShareView.joins(pet_profile_share: :pet).where(pets: { user_id: current_user.id }).count
    @active_profile_shares_count = PetProfileShare.active.joins(:pet).where(pets: { user_id: current_user.id }).count

    render layout: "dashboard_new_design"
  end

  def new_design
    redirect_to root_path, status: :moved_permanently
  end

  private

  def latest_events_by_pet_id(pets)
    pet_ids = pets.map(&:id)
    return {} if pet_ids.empty?

    PetEvent.where(pet_id: pet_ids)
            .order(event_date: :desc, created_at: :desc)
            .to_a
            .group_by(&:pet_id)
            .transform_values(&:first)
  end
end
