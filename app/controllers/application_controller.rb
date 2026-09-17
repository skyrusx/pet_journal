class ApplicationController < ActionController::Base
  include PublicFormProtection

  allow_browser versions: :modern

  before_action :redirect_to_canonical_host
  around_action :use_user_time_zone, if: :user_signed_in?
  before_action :track_user_activity, if: :user_signed_in?
  before_action :configure_permitted_parameters, if: :devise_controller?
  after_action :set_search_engine_indexing_header

  helper_method :canonical_url

  protected

  def allow_search_engine_indexing
    @search_engine_indexable = true
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: %i[name personal_data_consent])
    devise_parameter_sanitizer.permit(:account_update, keys: %i[name phone avatar remove_avatar])
  end

  private

  def canonical_host
    ENV.fetch("APP_HOST", "pet-journal.ru")
  end

  def canonical_url
    "https://#{canonical_host}#{request.path}"
  end

  def redirect_to_canonical_host
    return unless Rails.env.production?
    return if request.path == rails_health_check_path
    return if request.host == canonical_host

    redirect_to "https://#{canonical_host}#{request.fullpath}",
                status: :moved_permanently,
                allow_other_host: true
  end

  def set_search_engine_indexing_header
    return unless response.media_type == "text/html"
    return if @search_engine_indexable

    response.set_header("X-Robots-Tag", "noindex, nofollow")
  end

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
