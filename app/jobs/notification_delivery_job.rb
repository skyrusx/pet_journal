class NotificationDeliveryJob < ApplicationJob
  queue_as :default

  def perform(delivery)
    return if delivery.status_sent?

    unless delivery.notification_channel.ready_for_delivery?
      delivery.mark_skipped!(delivery.notification_channel.configuration_issues.to_sentence)
      return
    end

    delivery.register_attempt!
    NotificationAdapters.for(delivery.notification_channel).deliver(delivery)
    delivery.mark_sent!
    delivery.notification_channel.mark_verified!
  rescue StandardError => e
    delivery.mark_failed!(e.message)
  end
end
