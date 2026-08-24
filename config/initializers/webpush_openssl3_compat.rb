# frozen_string_literal: true

require "webpush"

# webpush 1.1.0 creates and mutates EC keys using APIs that became immutable
# with OpenSSL 3. Ruby 3.1+ commonly uses OpenSSL 3, so key generation and
# VAPID signing fail with `pkeys are immutable on OpenSSL 3.0` without this
# compatibility layer.
#
# Keep the public API of Webpush::VapidKey intact, but construct complete EC
# keys instead of assigning public_key/private_key after initialization.
if OpenSSL::OPENSSL_VERSION_NUMBER >= 0x30000000
  class Webpush::VapidKey
    CURVE_NAME = "prime256v1" unless const_defined?(:CURVE_NAME)

    class << self
      def from_keys(public_key, private_key)
        key = allocate
        key.instance_variable_set(:@curve, build_curve(public_key, private_key))
        key
      end

      def from_pem(pem)
        key = allocate
        key.instance_variable_set(:@curve, OpenSSL::PKey.read(pem))
        key
      end

      private

      def build_curve(public_key, private_key)
        public_bytes = Webpush.decode64(public_key)
        private_bytes = Webpush.decode64(private_key).rjust(32, "\0")

        ec_private_key = OpenSSL::ASN1::Sequence([
          OpenSSL::ASN1::Integer(1),
          OpenSSL::ASN1::OctetString(private_bytes),
          OpenSSL::ASN1::ASN1Data.new(
            [OpenSSL::ASN1::ObjectId(CURVE_NAME)],
            0,
            :CONTEXT_SPECIFIC
          ),
          OpenSSL::ASN1::ASN1Data.new(
            [OpenSSL::ASN1::BitString(public_bytes)],
            1,
            :CONTEXT_SPECIFIC
          )
        ])

        OpenSSL::PKey::EC.new(ec_private_key.to_der)
      end
    end

    def initialize
      @curve = OpenSSL::PKey::EC.generate(CURVE_NAME)
    end

    def to_pem
      curve.to_pem
    end
  end
end
