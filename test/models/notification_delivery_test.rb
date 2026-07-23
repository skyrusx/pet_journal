require "test_helper"

class NotificationDeliveryTest < ActiveSupport::TestCase
  test "failed delivery stays pending until max attempts" do
    delivery = notification_deliveries(:pending)
    delivery.update!(attempts_count: 1)

    delivery.mark_failed!("temporary error")

    assert delivery.status_pending?
    assert_not_nil delivery.next_attempt_at
    assert_equal "temporary error", delivery.error_message
  end

  test "failed delivery becomes failed after max attempts" do
    delivery = notification_deliveries(:pending)
    delivery.update!(attempts_count: NotificationDelivery::MAX_ATTEMPTS)

    delivery.mark_failed!("permanent error")

    assert delivery.status_failed?
    assert_nil delivery.next_attempt_at
  end
end
