class NotificationChannelsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_channel, only: %i[edit update destroy test]

  def index
    @channels = current_user.notification_channels.order(:channel_type, :created_at)
    @deliveries = NotificationDelivery
                  .joins(reminder: :pet)
                  .where(pets: { user_id: current_user.id })
                  .includes(:notification_channel, reminder: :pet)
                  .recent
                  .limit(30)
    @vapid_public_key = ENV["VAPID_PUBLIC_KEY"]
  end

  def new
    @channel = current_user.notification_channels.new(channel_type: params[:type].presence || :email)
  end

  def create
    @channel = current_user.notification_channels.new(channel_params)
    apply_web_push_settings
    mark_verification

    if @channel.save
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

    if @channel.save
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
    NotificationDeliveryJob.perform_later(delivery)

    redirect_to notification_channels_path, notice: "Тестовая отправка поставлена в очередь."
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

  def apply_web_push_settings
    return unless @channel.channel_web_push?

    @channel.settings = {
      "endpoint" => params[:notification_channel][:endpoint],
      "p256dh" => params[:notification_channel][:p256dh],
      "auth" => params[:notification_channel][:auth]
    }
  end

  def mark_verification
    @channel.verified_at ||= Time.current if @channel.channel_email?
  end
end
