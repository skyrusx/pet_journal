# frozen_string_literal: true

require "digest"

module SecurityRateLimitKey
  module_function

  PET_TAG_LOCATION_PATH = %r{\A/p/([^/]+)/location\z}

  def email(request)
    raw_email = request.params.dig("user", "email").to_s.strip.downcase
    return if raw_email.blank?

    Digest::SHA256.hexdigest(raw_email)
  rescue StandardError
    nil
  end

  def pet_tag_token(request)
    match = PET_TAG_LOCATION_PATH.match(request.path)
    match && Digest::SHA256.hexdigest(match[1])
  end

  def sanitized_path(request)
    request.path
           .sub(%r{\A/p/[^/]+}, "/p/[FILTERED]")
           .sub(%r{\A/share/[^/]+}, "/share/[FILTERED]")
  end
end

Rack::Attack.cache.store = if Rails.cache.is_a?(ActiveSupport::Cache::NullStore)
  ActiveSupport::Cache::MemoryStore.new
else
  Rails.cache
end

Rack::Attack.enabled = !Rails.env.test? && ActiveModel::Type::Boolean.new.cast(ENV.fetch("RACK_ATTACK_ENABLED", "true"))

Rack::Attack.throttle("security/register/ip", limit: 5, period: 10.minutes) do |request|
  request.ip if request.post? && request.path == "/register"
end

Rack::Attack.throttle("security/login/ip", limit: 20, period: 5.minutes) do |request|
  request.ip if request.post? && request.path == "/login"
end

Rack::Attack.throttle("security/login/email", limit: 10, period: 10.minutes) do |request|
  SecurityRateLimitKey.email(request) if request.post? && request.path == "/login"
end

Rack::Attack.throttle("security/password_reset/ip", limit: 5, period: 1.hour) do |request|
  request.ip if request.post? && request.path == "/password"
end

Rack::Attack.throttle("security/password_reset/email", limit: 3, period: 1.hour) do |request|
  SecurityRateLimitKey.email(request) if request.post? && request.path == "/password"
end

Rack::Attack.throttle("security/public_pet_tag/show/ip", limit: 30, period: 5.minutes) do |request|
  request.ip if request.get? && request.path.match?(%r{\A/p/[^/]+\z})
end

Rack::Attack.throttle("security/public_pet_tag/location/ip", limit: 10, period: 10.minutes) do |request|
  request.ip if request.post? && request.path.match?(SecurityRateLimitKey::PET_TAG_LOCATION_PATH)
end

Rack::Attack.throttle("security/public_pet_tag/location/token", limit: 5, period: 10.minutes) do |request|
  SecurityRateLimitKey.pet_tag_token(request) if request.post?
end

Rack::Attack.throttle("security/public_profile_share/show/ip", limit: 60, period: 5.minutes) do |request|
  request.ip if request.get? && request.path.match?(%r{\A/share/[^/]+\z})
end

Rack::Attack.throttled_response_retry_after_header = true
Rack::Attack.throttled_responder = lambda do |request|
  match_data = request.env["rack.attack.match_data"] || {}
  period = match_data[:period].to_i
  epoch_time = match_data[:epoch_time].to_i
  retry_after = if period.positive? && epoch_time.positive?
    period - (epoch_time % period)
  else
    60
  end
  message = "Слишком много попыток. Попробуйте ещё раз немного позже."

  if request.get_header("HTTP_ACCEPT").to_s.include?("application/json")
    body = { error: "too_many_requests", message: message }.to_json
    [429, { "Content-Type" => "application/json; charset=utf-8", "Cache-Control" => "no-store", "Retry-After" => retry_after.to_s }, [body]]
  else
    error_page = Rails.root.join("public/429.html")
    body = File.exist?(error_page) ? File.binread(error_page) : message
    [429, { "Content-Type" => "text/html; charset=utf-8", "Cache-Control" => "no-store", "Retry-After" => retry_after.to_s }, [body]]
  end
end

ActiveSupport::Notifications.subscribe("throttle.rack_attack") do |_name, _start, _finish, _id, payload|
  request = payload[:request]
  next unless request

  Rails.logger.warn(
    "[security] rate_limited " \
    "ip=#{request.ip} method=#{request.request_method} path=#{SecurityRateLimitKey.sanitized_path(request)} " \
    "rule=#{request.env['rack.attack.matched']}"
  )
end
