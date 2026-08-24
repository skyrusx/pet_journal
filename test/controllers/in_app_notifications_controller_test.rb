require "test_helper"

class InAppNotificationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in @user
    @notification = InAppNotification.for_reminder!(reminders(:one))
  end

  test "shows notification center" do
    get notifications_url

    assert_response :success
    assert_select ".pj-inbox-item", minimum: 1
    assert_select ".pj-inbox-item", text: /#{Regexp.escape(reminders(:one).title)}/
  end

  test "opening notification marks it read and redirects to target" do
    get notification_url(@notification)

    assert_redirected_to @notification.target_path
    assert_not_nil @notification.reload.read_at
  end

  test "marks all notifications read" do
    second = InAppNotification.create!(
      user: @user,
      kind: "test",
      title: "Второе уведомление",
      source_key: "test:second",
      occurred_at: Time.current
    )

    assert_nil @notification.read_at
    assert_nil second.read_at

    patch mark_all_read_notifications_url

    assert_redirected_to notifications_url
    assert_empty @user.in_app_notifications.unread.reload
  end

  test "cannot open another user's notification" do
    other = InAppNotification.create!(
      user: users(:two),
      kind: "test",
      title: "Чужое уведомление",
      source_key: "test:other",
      occurred_at: Time.current
    )

    get notification_url(other)

    assert_response :not_found
  end
end
