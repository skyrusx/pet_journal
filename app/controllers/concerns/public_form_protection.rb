# frozen_string_literal: true

module PublicFormProtection
  extend ActiveSupport::Concern

  MINIMUM_FORM_AGE = 2.seconds
  TOKEN_PURPOSE = :public_form_submission
  HONEYPOT_FIELD = :contact_website
  PUBLIC_FORM_PATHS = %w[/register /login /password].freeze
  PET_TAG_LOCATION_PATH = %r{\A/p/[^/]+/location\z}

  included do
    before_action :protect_public_form_submission!, if: :public_form_protection_required?
    helper_method :public_form_security_token
  end

  private

  def public_form_protection_required?
    return false unless request.post?

    PUBLIC_FORM_PATHS.include?(request.path) || request.path.match?(PET_TAG_LOCATION_PATH)
  end

  def protect_public_form_submission!
    if params[HONEYPOT_FIELD].present?
      log_public_form_security_event("honeypot")
      head :unprocessable_entity
      return
    end

    log_public_form_security_event("suspicious_timing") if suspicious_public_form_timing?
  end

  def public_form_security_token
    @public_form_security_token ||= public_form_verifier.generate(
      Time.current.to_i,
      purpose: TOKEN_PURPOSE
    )
  end

  def suspicious_public_form_timing?
    token = params[:security_form_token].to_s
    return true if token.blank?

    issued_at = public_form_verifier.verify(token, purpose: TOKEN_PURPOSE).to_i
    Time.current.to_i - issued_at < MINIMUM_FORM_AGE.to_i
  rescue ActiveSupport::MessageVerifier::InvalidSignature, TypeError, ArgumentError
    true
  end

  def public_form_verifier
    Rails.application.message_verifier("public-form-security")
  end

  def log_public_form_security_event(reason)
    Rails.logger.warn(
      "[security] public_form_suspicious " \
      "ip=#{request.remote_ip} method=#{request.request_method} path=#{sanitized_public_form_path} reason=#{reason}"
    )
  end

  def sanitized_public_form_path
    request.path.sub(%r{\A/p/[^/]+}, "/p/[FILTERED]")
  end
end
