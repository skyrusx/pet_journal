class Admin::UsersController < Admin::ApplicationController
  PER_PAGE = 25

  def index
    scope = User.order(created_at: :desc)
    @query = params[:q].to_s.strip
    @role_filter = params[:role].to_s
    @activity_filter = params[:activity].to_s
    @registered_filter = params[:registered].to_s
    @usage_filter = params[:usage].to_s

    if @query.present?
      pattern = "%#{ActiveRecord::Base.sanitize_sql_like(@query)}%"
      scope = scope.where("users.email ILIKE :pattern OR users.name ILIKE :pattern", pattern: pattern)
    end

    scope = scope.where(role: @role_filter) if %w[user admin].include?(@role_filter)

    scope = case @activity_filter
            when "7_days" then scope.where(last_seen_at: 7.days.ago..Time.current)
            when "30_days" then scope.where(last_seen_at: 30.days.ago..Time.current)
            when "never" then scope.where(last_seen_at: nil)
            else scope
            end

    scope = case @registered_filter
            when "7_days" then scope.where(created_at: 7.days.ago.beginning_of_day..Time.current)
            when "30_days" then scope.where(created_at: 29.days.ago.beginning_of_day..Time.current)
            else scope
            end

    scope = case @usage_filter
            when "with_pet" then scope.joins(:pets).distinct
            when "with_event" then scope.joins(pets: :pet_events).distinct
            when "with_reminder" then scope.joins(pets: :reminders).distinct
            when "with_pettag" then scope.joins(pets: :pet_tag).distinct
            else scope
            end

    @total_users = scope.count
    @total_pages = [(@total_users.to_f / PER_PAGE).ceil, 1].max
    requested_page = [params.fetch(:page, 1).to_i, 1].max
    @page = [requested_page, @total_pages].min
    @users = scope.includes(:pets).offset((@page - 1) * PER_PAGE).limit(PER_PAGE)
  end

  def show
    @user = User.includes(:pets).find(params[:id])
  end
end