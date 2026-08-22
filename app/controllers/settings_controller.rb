class SettingsController < ApplicationController
  layout "workspace_new_design"

  before_action :authenticate_user!

  def edit
    @time_zones = ActiveSupport::TimeZone.all
  end

  def update
    @time_zones = ActiveSupport::TimeZone.all

    if current_user.update(settings_params)
      redirect_to settings_path, notice: "Настройки сохранены."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def settings_params
    params.require(:user).permit(:interface_text_size, :notifications_time_zone)
  end
end
