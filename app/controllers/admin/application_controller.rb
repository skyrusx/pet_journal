class Admin::ApplicationController < ApplicationController
  layout "admin"

  before_action :authenticate_user!
  before_action :require_admin!

  private

  def require_admin!
    return if current_user.admin?

    redirect_to root_path, alert: "У вас нет доступа к разделу управления."
  end
end
