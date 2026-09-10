module Admin
  class UsersController < BaseController
    PER_PAGE = 25

    def index
      scope = User.order(created_at: :desc)

      if params[:q].present?
        query = ActiveRecord::Base.sanitize_sql_like(params[:q].to_s.strip)
        scope = scope.where("users.name ILIKE :query OR users.email ILIKE :query", query: "%#{query}%")
      end

      @total_users = scope.count
      @total_pages = [(@total_users.to_f / PER_PAGE).ceil, 1].max
      @page = params.fetch(:page, 1).to_i.clamp(1, @total_pages)
      @users = scope.with_attached_avatar
                    .includes(:pets)
                    .offset((@page - 1) * PER_PAGE)
                    .limit(PER_PAGE)
    end

    def show
      @user = User.with_attached_avatar.includes(:pets).find(params[:id])
    end
  end
end
