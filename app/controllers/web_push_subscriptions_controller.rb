class WebPushSubscriptionsController < ApplicationController
  before_action :authenticate_user!

  def create
    subscription = params.require(:subscription).permit(:endpoint, keys: %i[p256dh auth])
    keys = subscription.fetch(:keys, {})

    channel = current_user.notification_channels.find_or_initialize_by(
      channel_type: :web_push,
      address: subscription[:endpoint]
    )
    channel.assign_attributes(
      name: "Браузер #{Time.current.strftime("%d.%m.%Y %H:%M")}",
      enabled: true,
      verified_at: Time.current,
      settings: {
        "endpoint" => subscription[:endpoint],
        "p256dh" => keys[:p256dh],
        "auth" => keys[:auth]
      }
    )

    if channel.save
      render json: { ok: true, message: "Push-уведомления включены." }
    else
      render json: { ok: false, message: channel.errors.full_messages.to_sentence }, status: :unprocessable_entity
    end
  end
end
