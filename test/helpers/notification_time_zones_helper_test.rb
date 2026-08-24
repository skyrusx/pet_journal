require "test_helper"

class NotificationTimeZonesHelperTest < ActionView::TestCase
  include NotificationTimeZonesHelper

  test "uses Russian labels for notification time zones" do
    labels_by_value = notification_time_zone_options.to_h.invert

    assert_match "Новосибирск", labels_by_value.fetch("Novosibirsk")
    assert_match "Москва", labels_by_value.fetch("Moscow")
    assert_match "Лондон", labels_by_value.fetch("London")
    assert_match "Токио", labels_by_value.fetch("Tokyo")
  end
end
