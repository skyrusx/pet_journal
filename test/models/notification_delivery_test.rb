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

  test "delivery can be skipped with diagnostic message" do
    delivery = notification_deliveries(:pending)

    delivery.mark_skipped!("Канал не настроен")

    assert delivery.status_skipped?
    assert_equal "Канал не настроен", delivery.error_message
    assert_nil delivery.next_attempt_at
  end

  test "delivery can be reset for manual retry" do
    delivery = notification_deliveries(:pending)
    delivery.update!(status: :failed, error_message: "Ошибка", next_attempt_at: 1.hour.from_now)

    delivery.reset_for_retry!

    assert delivery.status_pending?
    assert_nil delivery.error_message
    assert_nil delivery.next_attempt_at
  end
end
