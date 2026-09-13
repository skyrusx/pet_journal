class Admin::PetsController < Admin::ApplicationController
  PER_PAGE = 25

  def index
    scope = Pet.joins(:user)
               .left_joins(:pet_tag)
               .includes(:user, :pet_tag)
               .with_attached_photo
               .order(created_at: :desc)

    @query = params[:q].to_s.strip
    @species = params[:species].to_s.strip
    @pet_tag_filter = params[:pet_tag].to_s
    @lost_filter = params[:lost].to_s
    @created_filter = params[:created].to_s
    @owner_role_filter = params[:owner_role].to_s

    if @query.present?
      pattern = "%#{ActiveRecord::Base.sanitize_sql_like(@query)}%"
      scope = scope.where(
        "pets.name ILIKE :pattern OR pets.breed ILIKE :pattern OR pets.chip_number ILIKE :pattern OR " \
        "users.name ILIKE :pattern OR users.email ILIKE :pattern",
        pattern:
      )
    end

    scope = scope.where(species: @species) if @species.present?
    scope = scope.where(users: { role: @owner_role_filter }) if %w[user admin].include?(@owner_role_filter)

    scope =
      case @created_filter
      when "7_days" then scope.where(pets: { created_at: 7.days.ago.beginning_of_day..Time.current })
      when "30_days" then scope.where(pets: { created_at: 29.days.ago.beginning_of_day..Time.current })
      else scope
      end

    scope =
      case @pet_tag_filter
      when "with" then scope.where.not(pet_tags: { id: nil })
      when "without" then scope.where(pet_tags: { id: nil })
      else scope
      end

    if @lost_filter == "1"
      scope = scope.where(pet_tags: { safety_status: PetTag.safety_statuses.fetch("lost") })
    end

    @species_options = Pet.where.not(species: [nil, ""]).distinct.order(:species).pluck(:species)
    @total_pets = scope.count
    @total_pages = [(@total_pets.to_f / PER_PAGE).ceil, 1].max
    requested_page = [params.fetch(:page, 1).to_i, 1].max
    @page = [requested_page, @total_pages].min
    @pets = scope.offset((@page - 1) * PER_PAGE).limit(PER_PAGE)
  end

  def show
    @pet = Pet.includes(:user, :pet_tag, :pet_documents, :pet_profile_shares)
              .with_attached_photo
              .find(params[:id])
    @recent_events = @pet.pet_events.order(event_date: :desc, created_at: :desc).limit(5)
    @upcoming_reminders = @pet.reminders.status_active.order(next_run_at: :asc).limit(5)
  end
end
