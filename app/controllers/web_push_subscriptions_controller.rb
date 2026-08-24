class WebPushSubscriptionsController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_web_push_configured!, only: :create

  def create
    subscription = params.require(:subscription).permit(:endpoint, keys: %i[p256dh auth])
    keys = subscription.fetch(:keys, {})
    endpoint = subscription[:endpoint].to_s

    channel = current_user.notification_channels.find_or_initialize_by(
      channel_type: :web_push,
      address: endpoint
    )
    channel.name = "Браузер #{Time.current.strftime("%d.%m.%Y %H:%M")}" if channel.new_record?
    channel.assign_attributes(
      enabled: true,
      verified_at: Time.current,
      settings: {
        "endpoint" => endpoint,
        "p256dh" => keys[:p256dh],
        "auth" => keys[:auth]
      }
    )

    if channel.save
      render json: {
        ok: true,
        active: true,
        channel_id: channel.id,
        message: "Push-уведомления включены для этого браузера."
      }
    else
      render json: { ok: false, message: channel.errors.full_messages.to_sentence }, status: :unprocessable_entity
    end
  end

  def destroy
    endpoint = params.require(:endpoint).to_s
    channels = current_user.notification_channels.channel_web_push.where(address: endpoint)
    channels.destroy_all

    render json: { ok: true, active: false, message: "Push-уведомления для этого браузера отключены." }
  end

  private

  def ensure_web_push_configured!
    return if WebPushConfiguration.configured?

    render json: {
      ok: false,
      message: "Web Push временно недоступен: на сервере не настроены VAPID-ключи."
    }, status: :service_unavailable
  end
end
