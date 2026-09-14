class PetsController < ApplicationController
  PAGE_SIZE = 25
  MOBILE_PAGE_SIZE = 10

  before_action :authenticate_user!
  before_action :set_pet, only: %i[show edit update destroy]

  layout "workspace_new_design"

  def index
    @page = [params[:page].to_i, 1].max
    @page_size = mobile_request? ? MOBILE_PAGE_SIZE : PAGE_SIZE
    @pets_limit = @page_size * @page
    @matching_pets_count = current_user.pets.count
    @has_more_pets = @matching_pets_count > @pets_limit
    @pets = current_user.pets
                        .with_attached_photo
                        .includes(:pet_tag, :reminders, pet_photos: { image_attachment: :blob })
                        .order(created_at: :desc)
                        .limit(@pets_limit)
                        .to_a
    @latest_events_by_pet_id = latest_events_by_pet_id(@pets)
    @active_reminders_count = current_user.reminders.status_active.count
    @overdue_reminders_count = current_user.reminders.overdue.count
    @pet_tag_scans_count = PetTagScan.joins(pet_tag: :pet).where(pets: { user_id: current_user.id }).count
    @active_profile_shares_count = PetProfileShare.active.joins(:pet).where(pets: { user_id: current_user.id }).count
  end

  def show
    @pet_photos = @pet.pet_photos.with_attached_image.ordered.to_a
    @recent_events = @pet.pet_events.with_attached_files.order(event_date: :desc, created_at: :desc).limit(5)
    @events_count = @pet.pet_events.count
    @latest_events_by_type = latest_events_by_type(@pet)
    @attached_files_count = @pet.pet_events.joins(:files_attachments).count
    @documents_count = @pet.pet_documents.count
    @document_events = @pet.pet_documents.with_attached_files.order(created_at: :desc).limit(3)
    @expiring_documents = @pet.pet_documents.expires_soon.limit(3)
    @expiring_documents_count = @pet.pet_documents.expires_soon.count
    @pet_tag = @pet.pet_tag
    @latest_pet_tag_scan = @pet_tag&.pet_tag_scans&.order(created_at: :desc)&.first
    @pet_tag_scan_count = @pet_tag&.pet_tag_scans&.count.to_i
    @next_reminder = @pet.reminders.status_active.order(:next_run_at).first
    @upcoming_reminders = @pet.reminders.status_active.order(:next_run_at).limit(3)
    @active_reminders_count = @pet.reminders.status_active.count
    @overdue_reminders_count = @pet.reminders.overdue.count
    @today_reminders_count = @pet.reminders.status_active.where(next_run_at: Time.current.beginning_of_day..Time.current.end_of_day).count
    @active_profile_shares = @pet.pet_profile_shares.active.order(created_at: :desc).limit(3)
    @profile_shares_count = @pet.pet_profile_shares.count
    @active_profile_shares_count = @pet.pet_profile_shares.active.count
    @profile_share_views_count = PetProfileShareView.joins(:pet_profile_share).where(pet_profile_shares: { pet_id: @pet.id }).count
    @latest_profile_share_view = PetProfileShareView.joins(:pet_profile_share)
                                                    .where(pet_profile_shares: { pet_id: @pet.id })
                                                    .order(created_at: :desc)
                                                    .first
  end

  def new
    @pet = current_user.pets.new
  end

  def create
    @pet = current_user.pets.new(pet_params)

    Pet.transaction do
      @pet.save!
      PetPhotoManager.new(@pet).add!(photo_uploads)
    end

    redirect_to @pet, notice: "Питомец добавлен."
  rescue ActiveRecord::RecordInvalid, PetPhotoManager::Error => e
    add_photo_error(e)
    render :new, status: :unprocessable_entity
  end

  def edit; end

  def update
    Pet.transaction do
      @pet.update!(pet_params)
      PetPhotoManager.new(@pet).add!(photo_uploads)
    end

    redirect_to @pet, notice: "Данные питомца обновлены."
  rescue ActiveRecord::RecordInvalid, PetPhotoManager::Error => e
    add_photo_error(e)
    render :edit, status: :unprocessable_entity
  end

  def destroy
    pet_name = @pet.name
    @pet.destroy!

    redirect_to pets_path, notice: "Профиль #{pet_name} удалён."
  end

  private

  def set_pet
    @pet = current_user.pets.find(params[:id])
  end

  def pet_params
    params.require(:pet).permit(:name, :species, :breed, :sex, :birth_date, :weight, :color, :chip_number,
                                :passport_number, :neutered, :notes)
  end

  def photo_uploads
    Array(params.dig(:pet, :photos)).reject(&:blank?)
  end

  def add_photo_error(error)
    return unless @pet.errors.empty?

    message = error.respond_to?(:record) ? error.record.errors.full_messages.to_sentence : error.message
    @pet.errors.add(:base, message)
  end

  def latest_events_by_pet_id(pets)
    pet_ids = pets.map(&:id)
    return {} if pet_ids.empty?

    PetEvent.where(pet_id: pet_ids)
            .order(event_date: :desc, created_at: :desc)
            .to_a
            .group_by(&:pet_id)
            .transform_values(&:first)
  end

  def latest_events_by_type(pet)
    pet.pet_events
       .order(event_date: :desc, created_at: :desc)
       .to_a
       .group_by(&:event_type)
       .transform_values(&:first)
  end
end
