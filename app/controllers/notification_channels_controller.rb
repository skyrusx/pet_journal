class NotificationChannelsController < ApplicationController
  layout "workspace_new_design"

  DELIVERY_PAGE_SIZE = 25
  DELIVERY_MOBILE_PAGE_SIZE = 10

  before_action :authenticate_user!
  before_action :set_channel, only: %i[edit update destroy test]
  before_action :set_delivery, only: %i[retry_delivery]

  def index
    @channels = current_user.notification_channels.order(:channel_type, :created_at)
    @selected_delivery_status = params[:delivery_status].presence_in(%w[all pending sent failed skipped]) || "all"
    @page = [params[:page].to_i, 1].max
    @delivery_page_size = mobile_request? ? DELIVERY_MOBILE_PAGE_SIZE : DELIVERY_PAGE_SIZE
    @deliveries_limit = @delivery_page_size * @page

    deliveries_scope = filtered_deliveries
    @matching_deliveries_count = deliveries_scope.count
    @has_more_deliveries = @matching_deliveries_count > @deliveries_limit
    @deliveries = deliveries_scope.limit(@deliveries_limit)
    @delivery_counts = delivery_counts
    @vapid_public_key = WebPushConfiguration.public_key
  end

  def new
    available_types = %w[email vk]
    available_types << "telegram" if TelegramConfiguration.configured?
    requested_type = params[:type].presence_in(available_types) || "email"

    @channel = current_user.notification_channels.new(
      channel_type: requested_type,
      name: default_channel_name(requested_type)
    )
  end

  def create
    @channel = current_user.notification_channels.new(channel_params)

    unless channel_available_for_creation?(@channel)
      @channel.errors.add(:channel_type, "Telegram пока в разработке и недоступен для подключения.")
      render :new, status: :unprocessable_entity
      return
    end

    apply_web_push_settings
    mark_verification

    if prepare_channel_for_save && @channel.save
      redirect_to notification_channels_path, notice: "Канал уведомлений добавлен."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    @channel.assign_attributes(channel_params)
    apply_web_push_settings
    mark_verification

    if prepare_channel_for_save && @channel.save
      redirect_to notification_channels_path, notice: "Канал уведомлений обновлен."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @channel.destroy

    redirect_to notification_channels_path, notice: "Канал уведомлений удален."
  end

  def test
    reminder = current_user.pets.first&.reminders&.first

    if reminder.blank?
      redirect_to notification_channels_path, alert: "Создайте питомца и напоминание для тестовой отправки."
      return
    end

    delivery = reminder.notification_deliveries.create!(notification_channel: @channel)
    NotificationDeliveryJob.perform_now(delivery, test_delivery: true)

    if delivery.reload.status_sent?
      redirect_to notification_channels_path, notice: "Тестовая отправка выполнена."
    else
      redirect_to notification_channels_path, alert: "Тестовая отправка не прошла: #{delivery.error_message}"
    end
  end

  def retry_delivery
    @delivery.reset_for_retry!
    NotificationDeliveryJob.perform_now(@delivery)

    if @delivery.reload.status_sent?
      redirect_to notification_channels_path(delivery_status: :sent), notice: "Отправка выполнена повторно."
    else
      redirect_to notification_channels_path(delivery_status: @delivery.status), alert: "Повторная отправка не прошла: #{@delivery.error_message}"
    end
  end

  def update_settings
    if current_user.update(notification_settings_params)
      redirect_to notification_channels_path, notice: "Настройки уведомлений обновлены."
    else
      redirect_to notification_channels_path, alert: current_user.errors.full_messages.to_sentence
    end
  end

  private

  def set_channel
    @channel = current_user.notification_channels.find(params[:id])
  end

  def set_delivery
    @delivery = delivery_scope.find(params[:delivery_id])
  end

  def channel_params
    params.require(:notification_channel).permit(:channel_type, :name, :address, :enabled)
  end

  def notification_settings_params
    params.require(:user).permit(
      :notifications_quiet_hours_enabled,
      :notifications_quiet_hours_start,
      :notifications_quiet_hours_end,
      :notifications_time_zone
    )
  end

  def channel_available_for_creation?(channel)
    !channel.channel_telegram? || TelegramConfiguration.configured?
  end

  def apply_web_push_settings
    return unless @channel.channel_web_push?

    @channel.settings = {
      "endpoint" => params[:notification_channel][:endpoint],
      "p256dh" => params[:notification_channel][:p256dh],
      "auth" => params[:notification_channel][:auth]
    }
  end

  def prepare_channel_for_save
    return true unless @channel.channel_vk?

    resolved = NotificationChannelConnectors::VkProfileResolver.call(@channel.address)
    @channel.address = resolved.user_id
    @channel.settings = @channel.settings.merge(
      "screen_name" => resolved.screen_name,
      "display_name" => resolved.display_name
    ).compact
    true
  rescue NotificationChannelConnectors::VkProfileResolver::Error => e
    @channel.errors.add(:address, e.message)
    false
  end

  def mark_verification
    @channel.verified_at ||= Time.current if @channel.channel_email?
  end

  def default_channel_name(channel_type)
    {
      "email" => "Email",
      "telegram" => "Telegram",
      "vk" => "ВКонтакте"
    }.fetch(channel_type, "Канал")
  end

  def filtered_deliveries
    scope = delivery_scope.includes(:notification_channel, reminder: :pet).recent
    return scope if @selected_delivery_status == "all"

    scope.where(status: NotificationDelivery.statuses.fetch(@selected_delivery_status))
  end

  def delivery_counts
    counts = delivery_scope.group(:status).count

    {
      all: counts.values.sum,
      pending: counts.fetch("pending", 0),
      sent: counts.fetch("sent", 0),
      failed: counts.fetch("failed", 0),
      skipped: counts.fetch("skipped", 0)
    }
  end

  def delivery_scope
    NotificationDelivery
      .joins(reminder: :pet)
      .where(pets: { user_id: current_user.id })
  end
end
