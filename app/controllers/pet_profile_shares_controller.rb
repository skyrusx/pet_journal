class PetProfileSharesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_pet
  before_action :set_pet_choices
  before_action :set_share, only: %i[show edit update destroy enable disable rotate_token qr]

  layout "workspace_new_design"

  def index
    @shares = @pet.pet_profile_shares.recent.includes(:pet_profile_share_views)
  end

  def show
    @views = @share.pet_profile_share_views.order(created_at: :desc).limit(40)
  end

  def new
    @share = @pet.pet_profile_shares.new(default_share_attributes)
  end

  def create
    @share = @pet.pet_profile_shares.new(share_params)
    apply_expiration_preset(@share)

    if @share.save
      redirect_to pet_profile_share_path(@pet, @share), notice: "Публичный доступ создан."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    @share.assign_attributes(share_params)
    apply_expiration_preset(@share)

    if @share.save
      redirect_to pet_profile_share_path(@pet, @share), notice: "Настройки доступа обновлены."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @share.destroy

    redirect_to pet_profile_shares_path(@pet), notice: "Публичный доступ удален."
  end

  def enable
    @share.update!(enabled: true)

    redirect_to pet_profile_share_path(@pet, @share), notice: "Публичный доступ включен."
  end

  def disable
    @share.update!(enabled: false)

    redirect_to pet_profile_share_path(@pet, @share), notice: "Публичный доступ отключен."
  end

  def rotate_token
    @share.regenerate_public_token
    @share.update!(token_rotated_at: Time.current)

    redirect_to pet_profile_share_path(@pet, @share), notice: "Публичная ссылка обновлена."
  end

  def qr
    qr_code = RQRCode::QRCode.new(public_pet_profile_share_url(@share.public_token))

    case params[:format]
    when "svg"
      send_data qr_code.as_svg(
                  module_size: 8,
                  standalone: true,
                  use_path: false,
                  shape_rendering: "crispEdges"
                ),
                filename: "#{@pet.name.parameterize.presence || "pet"}-profile-share.svg",
                type: "image/svg+xml"
    when "png"
      send_data qr_code.as_png(size: 1024).to_s,
                filename: "#{@pet.name.parameterize.presence || "pet"}-profile-share.png",
                type: "image/png"
    else
      head :not_found
    end
  end

  private

  def set_pet
    @pet = current_user.pets.find(params[:pet_id])
  end

  def set_pet_choices
    @pet_choices = current_user.pets.order(:name)
  end

  def set_share
    @share = @pet.pet_profile_shares.find(params[:id])
  end

  def share_params
    permitted = params.require(:pet_profile_share).permit(:title, :enabled, :expires_at, :detail_level, :show_profile,
                                                          :show_journal, :show_documents, :show_reminders, :show_pet_tag,
                                                          :show_owner_contact, :allow_file_downloads)
    permitted[:show_owner_contact] = false
    permitted
  end

  def default_share_attributes
    {
      title: "Профиль #{@pet.name}",
      enabled: true,
      expires_at: 7.days.from_now.end_of_day,
      detail_level: :brief,
      show_profile: true,
      show_journal: true,
      show_documents: true
    }
  end

  def apply_expiration_preset(share)
    case params[:expires_preset]
    when "one_day"
      share.expires_at = 1.day.from_now.end_of_day
    when "seven_days"
      share.expires_at = 7.days.from_now.end_of_day
    when "thirty_days"
      share.expires_at = 30.days.from_now.end_of_day
    when "never"
      share.expires_at = nil
    when "custom"
      share.expires_at = share.expires_at
    end
  end
end