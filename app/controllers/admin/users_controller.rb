class Admin::UsersController < Admin::ApplicationController
  PER_PAGE = 25

  def index
    scope = User.order(created_at: :desc)
    @query = params[:q].to_s.strip

    if @query.present?
      pattern = "%#{ActiveRecord::Base.sanitize_sql_like(@query)}%"
      scope = scope.where("users.email ILIKE :pattern OR users.name ILIKE :pattern", pattern: pattern)
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
