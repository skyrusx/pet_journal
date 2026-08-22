require "base64"
require "openssl"

class TelegramConnectionToken
  TTL = 30.minutes
  SIGNATURE_BYTES = 16

  class InvalidToken < StandardError; end

  def self.generate(user, issued_at: Time.current)
    payload = "#{user.id}:#{issued_at.to_i}"
    encoded_payload = Base64.urlsafe_encode64(payload, padding: false)
    signature = Base64.urlsafe_encode64(sign(encoded_payload), padding: false)

    "pj_#{encoded_payload}.#{signature}"
  end

  def self.resolve(token, now: Time.current)
    encoded_payload, encoded_signature = token.to_s.delete_prefix("pj_").split(".", 2)
    raise InvalidToken if encoded_payload.blank? || encoded_signature.blank?

    expected_signature = Base64.urlsafe_encode64(sign(encoded_payload), padding: false)
    raise InvalidToken unless secure_compare(encoded_signature, expected_signature)

    user_id, issued_at = Base64.urlsafe_decode64(pad64(encoded_payload)).split(":", 2)
    raise InvalidToken if user_id.blank? || issued_at.blank?

    issued_at = Time.at(Integer(issued_at))
    raise InvalidToken if issued_at > now + 1.minute || issued_at < now - TTL

    User.find(Integer(user_id))
  rescue ArgumentError, ActiveRecord::RecordNotFound
    raise InvalidToken
  end

  def self.sign(payload)
    OpenSSL::HMAC.digest("SHA256", secret, payload).byteslice(0, SIGNATURE_BYTES)
  end
  private_class_method :sign

  def self.secret
    ENV["TELEGRAM_CONNECTION_SECRET"].presence || Rails.application.secret_key_base
  end
  private_class_method :secret

  def self.secure_compare(left, right)
    left.bytesize == right.bytesize && ActiveSupport::SecurityUtils.secure_compare(left, right)
  end
  private_class_method :secure_compare

  def self.pad64(value)
    value + ("=" * ((4 - value.length % 4) % 4))
  end
  private_class_method :pad64
end
