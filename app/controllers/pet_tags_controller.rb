class PetTagsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_pet
  before_action :set_pet_tag, only: %i[show edit update rotate_token qr]

  def show
    @scan_count = @pet_tag.persisted? ? @pet_tag.pet_tag_scans.count : 0
    @recent_scans = @pet_tag.persisted? ? @pet_tag.pet_tag_scans.order(created_at: :desc).limit(5) : []
  end

  def create
    @pet_tag = @pet.build_pet_tag(pet_tag_params)

    if @pet_tag.save
      redirect_to pet_pet_tag_path(@pet), notice: "QR-профиль создан."
    else
      render :show, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @pet_tag.update(pet_tag_params)
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
                                      :notification_preference)
  end
end
