class SettingsController < ApplicationController
  layout "workspace_new_design"

  before_action :authenticate_user!

  def edit
    prepare_time_zone_options
  end

  def update
    prepare_time_zone_options

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

  def prepare_time_zone_options
    @time_zone_options = Settings::TimeZoneOptions.call
  end
end
