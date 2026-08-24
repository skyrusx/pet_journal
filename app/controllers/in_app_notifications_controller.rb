class InAppNotificationsController < ApplicationController
  layout "workspace_new_design"

  PAGE_SIZE = 25

  before_action :authenticate_user!
  before_action :set_notification, only: :show

  def index
    @page = [params[:page].to_i, 1].max
    @limit = PAGE_SIZE * @page
    scope = current_user.in_app_notifications.recent
    @total_count = scope.count
    @notifications = scope.limit(@limit)
    @has_more = @total_count > @limit
    @unread_count = current_user.in_app_notifications.unread.count
  end

  def show
    @notification.mark_read!
    redirect_to safe_target_path(@notification.target_path)
  end

  def mark_all_read
    current_user.in_app_notifications.unread.update_all(read_at: Time.current, updated_at: Time.current)
    redirect_back fallback_location: notifications_path, notice: "Все уведомления отмечены прочитанными."
  end

  private

  def set_notification
    @notification = current_user.in_app_notifications.find(params[:id])
  end

  def safe_target_path(path)
    value = path.to_s
    value.start_with?("/") && !value.start_with?("//") ? value : notifications_path
  end
end
