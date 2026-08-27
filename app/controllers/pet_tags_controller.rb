class PetTagsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_pet, except: :index
  before_action :set_pet_tag, only: %i[
    show edit update rotate_token qr mark_lost mark_found mark_reunited mark_safe
    phone_consent publish_phone revoke_phone
  ]
  before_action :set_notification_channels, only: %i[show edit update]

  layout "workspace_new_design"

  def index
    @pets = current_user.pets.includes(:pet_tag, photo_attachment: :blob).order(:name)

    if @pets.one?
      redirect_to pet_pet_tag_path(@pets.first)
      return
    end
  end

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
      set_notification_channels
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

  def phone_consent
    unless @pet_tag.persisted?
      redirect_to pet_pet_tag_path(@pet), alert: "Сначала создайте PetTag."
      return
    end

    unless @pet_tag.contact_phone.present?
      redirect_to edit_pet_pet_tag_path(@pet), alert: "Сначала укажите и сохраните телефон владельца."
      return
    end

    prepare_phone_consent_page
  end

  def publish_phone
    unless @pet_tag.persisted? && @pet_tag.contact_phone.present?
      redirect_to edit_pet_pet_tag_path(@pet), alert: "Сначала укажите и сохраните телефон владельца."
      return
    end

    @subject_full_name = params[:subject_full_name].to_s.squish
    prepare_phone_consent_page

    unless @operator_ready
      @consent_error = "Публикация телефона недоступна, пока не заполнены сведения об операторе."
      render :phone_consent, status: :unprocessable_entity
      return
    end

    unless valid_distribution_subject_name?(@subject_full_name)
      @consent_error = "Укажите фамилию и имя субъекта персональных данных. Отчество — при наличии."
      render :phone_consent, status: :unprocessable_entity
      return
    end

    unless params[:phone_distribution_consent].to_s == "1"
      @consent_error = "Чтобы опубликовать телефон, подтвердите отдельное согласие на его распространение."
      render :phone_consent, status: :unprocessable_entity
      return
    end

    @pet_tag.publish_phone!(
      user: current_user,
      subject_full_name: @subject_full_name,
      subject_contact: current_user.email,
      ip_address: request.remote_ip,
      user_agent: request.user_agent,
      public_url: @public_pet_tag_url
    )

    redirect_to edit_pet_pet_tag_path(@pet), notice: "Телефон опубликован на странице PetTag. Согласие зафиксировано."
  rescue ActiveRecord::RecordInvalid => e
    @consent_error = e.record.errors.full_messages.to_sentence.presence || "Не удалось зафиксировать согласие."
    prepare_phone_consent_page
    render :phone_consent, status: :unprocessable_entity
  end

  def revoke_phone
    unless @pet_tag.persisted?
      redirect_to pet_pet_tag_path(@pet), alert: "PetTag не найден."
      return
    end

    @pet_tag.revoke_phone_publication!
    redirect_to edit_pet_pet_tag_path(@pet), notice: "Публикация телефона отключена, согласие отозвано."
  end

  def rotate_token
    phone_consent_revoked = @pet_tag.active_phone_distribution_consent.present?
    @pet_tag.revoke_phone_publication! if phone_consent_revoked

    @pet_tag.regenerate_public_token
    @pet_tag.update!(token_rotated_at: Time.current)

    notice = "Публичная ссылка жетона обновлена. PetTag ID не изменился."
    notice += " Публикация телефона отключена — для новой публичной ссылки нужно подтвердить согласие заново." if phone_consent_revoked
    redirect_to pet_pet_tag_path(@pet), notice: notice
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

  def mark_safe
    @pet_tag.mark_safe!

    redirect_to pet_pet_tag_path(@pet), notice: "Инцидент завершен. PetTag снова в обычном режиме."
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
    params.require(:pet_tag).permit(:enabled, :public_message, :behavior_notes, :medical_notes, :contact_phone,
                                    :lost_mode_enabled, :lost_message, :last_seen_location,
                                    :notification_preference, :show_medical_notes, :found_message)
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

  def prepare_phone_consent_page
    @legal_document = LegalDocuments.fetch(:pet_tag_phone_distribution_consent)
    @operator_name = LegalOperatorConfiguration.name
    @operator_email = LegalOperatorConfiguration.email
    @operator_details = LegalOperatorConfiguration.details
    @operator_ready = !Rails.env.production? || @operator_details.present?
    @subject_full_name ||= current_user.name.to_s.squish
    @subject_contact = current_user.email
    @public_pet_tag_url = public_pet_tag_url(@pet_tag.public_token)
  end

  def valid_distribution_subject_name?(value)
    value.length <= 200 && value.split(/\s+/).size >= 2
  end
end
