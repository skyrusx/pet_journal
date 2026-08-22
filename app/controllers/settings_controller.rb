class SettingsController < ApplicationController
  layout "workspace_new_design"

  before_action :authenticate_user!

  RUSSIAN_TIME_ZONES = {
    "Kaliningrad" => "Калининград",
    "Moscow" => "Москва",
    "Samara" => "Самара",
    "Ekaterinburg" => "Екатеринбург",
    "Omsk" => "Омск",
    "Krasnoyarsk" => "Красноярск",
    "Irkutsk" => "Иркутск",
    "Yakutsk" => "Якутск",
    "Vladivostok" => "Владивосток",
    "Magadan" => "Магадан",
    "Kamchatka" => "Камчатка"
  }.freeze

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
    @time_zone_options = [["(UTC+00:00) Всемирное координированное время", "UTC"]]

    RUSSIAN_TIME_ZONES.each do |zone_name, russian_name|
      zone = ActiveSupport::TimeZone[zone_name]
      next unless zone

      @time_zone_options << ["(UTC#{zone.formatted_offset}) #{russian_name}", zone.name]
    end
  end
end
