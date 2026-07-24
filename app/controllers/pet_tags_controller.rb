class PetTagsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_pet
  before_action :set_pet_tag, only: %i[show edit update rotate_token qr mark_lost mark_found mark_reunited]
  before_action :set_notification_channels, only: %i[show edit update]

  def show
    @scan_count = @pet_tag.persisted? ? @pet_tag.pet_tag_scans.count : 0
    @selected_scan_status = params[:scan_status].presence_in(%w[all scanned location_shared found_reported]) || "all"
    @recent_scans = @pet_tag.persisted? ? filtered_scans.limit(30) : []
    @scan_counts = scan_counts
  end

  def create
    @pet_tag = @pet.build_pet_tag(pet_tag_params)

    if @pet_tag.save
      sync_notification_channels
      redirect_to pet_pet_tag_path(@pet), notice: "QR-профиль создан."
    else
      render :show, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @pet_tag.update(pet_tag_params)
      sync_notification_channels
      redirect_to pet_pet_tag_path(@pet), notice: "QR-профиль обновлен."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def rotate_token
    @pet_tag.regenerate_public_token
    @pet_tag.update!(token_rotated_at: Time.current)

    redirect_to pet_pet_tag_path(@pet), notice: "Публичная ссылка жетона обновлена."
  end

  def mark_lost
    @pet_tag.mark_lost!

    redirect_to pet_pet_tag_path(@pet), notice: "Режим потери включен."
  end

  def mark_found
    @pet_tag.mark_found!(message: params[:found_message])

    redirect_to pet_pet_tag_path(@pet), notice: "Статус жетона изменен на «найден»."
  end

  def mark_reunited
    @pet_tag.mark_reunited!

    redirect_to pet_pet_tag_path(@pet), notice: "Питомец отмечен как вернувшийся домой."
  end

  def qr
    qr_code = RQRCode::QRCode.new(public_pet_tag_url(@pet_tag.public_token))

    case params[:format]
    when "svg"
      send_data qr_code.as_svg(module_size: 8, standalone: true, use_path: true),
                filename: "#{@pet.name.parameterize.presence || "pet"}-pettag.svg",
                type: "image/svg+xml"
    when "png"
      send_data qr_code.as_png(size: 1024).to_s,
                filename: "#{@pet.name.parameterize.presence || "pet"}-pettag.png",
                type: "image/png"
    else
      head :not_found
    end
  end

  private

  def set_pet
    @pet = current_user.pets.find(params[:pet_id])
  end

  def set_pet_tag
    @pet_tag = @pet.pet_tag || @pet.build_pet_tag
  end

  def pet_tag_params
    params.fetch(:pet_tag, {}).permit(:enabled, :public_message, :behavior_notes, :medical_notes, :contact_phone,
                                      :show_phone, :lost_mode_enabled, :lost_message, :last_seen_location,
                                      :notification_preference, :safety_status, :show_medical_notes, :found_message)
  end

  def set_notification_channels
    @notification_channels = current_user.notification_channels.enabled.order(:channel_type, :created_at)
  end

  def sync_notification_channels
    channel_ids = Array(params.dig(:pet_tag, :notification_channel_ids)).reject(&:blank?)
    channels = current_user.notification_channels.enabled.where(id: channel_ids)

    @pet_tag.notification_channels = channels
  end

  def filtered_scans
    scope = @pet_tag.pet_tag_scans.order(created_at: :desc)
    return scope if @selected_scan_status == "all"
    return scope.where.not(location_shared_at: nil) if @selected_scan_status == "location_shared"

    scope.where(scan_status: @selected_scan_status)
  end

  def scan_counts
    return { total: 0, locations: 0, found: 0, notified: 0 } unless @pet_tag.persisted?

    scans = @pet_tag.pet_tag_scans
    {
      total: scans.count,
      locations: scans.where.not(location_shared_at: nil).count,
      found: scans.status_found_reported.count,
      notified: scans.where.not(owner_notified_at: nil).count
    }
  end
end
