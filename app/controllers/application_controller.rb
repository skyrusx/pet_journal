class ApplicationController < ActionController::Base
  include PublicFormProtection

  allow_browser versions: :modern

  around_action :use_user_time_zone, if: :user_signed_in?
  before_action :track_user_activity, if: :user_signed_in?
  before_action :configure_permitted_parameters, if: :devise_controller?

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: %i[name personal_data_consent])
    devise_parameter_sanitizer.permit(:account_update, keys: %i[name phone avatar remove_avatar])
  end

  private

  def mobile_request?
    return true if request.headers["Sec-CH-UA-Mobile"] == "?1"

    user_agent = request.user_agent.to_s
    %w[Android iPhone iPod IEMobile Mobile].any? { |marker| user_agent.include?(marker) }
  end

  def track_user_activity
    return if current_user.last_seen_at.present? && current_user.last_seen_at > 5.minutes.ago

    current_user.update_column(:last_seen_at, Time.current)
  end

  def use_user_time_zone(&block)
    Time.use_zone(current_user.notifications_time_zone_name, &block)
  end
end
