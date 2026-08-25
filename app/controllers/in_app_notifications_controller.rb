class InAppNotificationsController < ApplicationController
  layout "workspace_new_design"

  PAGE_SIZE = 25
  MOBILE_PAGE_SIZE = 10
  STATUS_FILTERS = %w[all unread read].freeze
  TYPE_FILTERS = %w[all reminder pet_tag].freeze

  before_action :authenticate_user!
  before_action :set_notification, only: :show

  def index
    @page = [params[:page].to_i, 1].max
    @page_size = mobile_request? ? MOBILE_PAGE_SIZE : PAGE_SIZE
    @limit = @page_size * @page
    @query = params[:q].to_s.strip
    @selected_status = STATUS_FILTERS.include?(params[:status]) ? params[:status] : "all"
    @selected_type = TYPE_FILTERS.include?(params[:type]) ? params[:type] : "all"

    scope = current_user.in_app_notifications.recent
    scope = apply_search(scope)
    scope = apply_status_filter(scope)
    scope = apply_type_filter(scope)

    @total_count = scope.count
    @notifications = scope.limit(@limit)
    @has_more = @total_count > @limit
    @unread_count = current_user.in_app_notifications.unread.count
    @has_filters = @query.present? || @selected_status != "all" || @selected_type != "all"
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

  def apply_search(scope)
    return scope if @query.blank?

    query = "%#{ActiveRecord::Base.sanitize_sql_like(@query)}%"
    scope.where("title ILIKE :query OR body ILIKE :query", query:)
  end

  def apply_status_filter(scope)
    case @selected_status
    when "unread"
      scope.unread
    when "read"
      scope.where.not(read_at: nil)
    else
      scope
    end
  end

  def apply_type_filter(scope)
    case @selected_type
    when "reminder"
      scope.where(kind: "reminder_due")
    when "pet_tag"
      scope.where("kind LIKE ?", "pet_tag%")
    else
      scope
    end
  end

  def mobile_request?
    return true if request.headers["Sec-CH-UA-Mobile"] == "?1"

    request.user_agent.to_s.match?(/Android|iPhone|iPod|IEMobile|Opera Mini|Mobile/i)
  end

  def safe_target_path(path)
    value = path.to_s
    value.start_with?("/") && !value.start_with?("//") ? value : notifications_path
  end
end
