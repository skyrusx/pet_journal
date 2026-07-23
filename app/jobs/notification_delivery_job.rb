class NotificationDeliveryJob < ApplicationJob
  queue_as :default

  def perform(delivery)
    NotificationAdapters.for(delivery.notification_channel).deliver(delivery)
    delivery.mark_sent!
  rescue StandardError => e
    delivery.mark_failed!(e.message)
  end
end
