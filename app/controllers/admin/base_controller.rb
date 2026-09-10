module Admin
  class BaseController < ApplicationController
    layout "admin"

    before_action :authenticate_user!
    before_action :require_admin!

    private

    def admin_access?
      current_user&.admin_access?
    end

    def require_admin!
      return if admin_access?

      redirect_to root_path, alert: "У вас нет доступа к разделу управления."
    end
  end
end
