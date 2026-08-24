# frozen_string_literal: true

require "webpush"

# webpush 1.1.0 creates and mutates EC keys using APIs that became immutable
# with OpenSSL 3. Ruby 3.1+ commonly uses OpenSSL 3, so both VAPID key handling
# and payload encryption fail with `pkeys are immutable on OpenSSL 3.0` unless
# complete EC keys are created in one operation.
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

  # webpush 1.1.0 also does this while encrypting every payload:
  #
  #   server = OpenSSL::PKey::EC.new("prime256v1")
  #   server.generate_key
  #
  # The second line mutates the key and raises on OpenSSL 3. Keep the gem's
  # encryption algorithm intact, replacing only key generation with the
  # OpenSSL-3-compatible constructor.
  module Webpush::Encryption
    class << self
      def encrypt(message, p256dh, auth)
        assert_arguments(message, p256dh, auth)

        group_name = "prime256v1"
        salt = Random.new.bytes(16)

        server = OpenSSL::PKey::EC.generate(group_name)
        server_public_key_bn = server.public_key.to_bn
        group = OpenSSL::PKey::EC::Group.new(group_name)
        client_public_key_bn = OpenSSL::BN.new(Webpush.decode64(p256dh), 2)
        client_public_key = OpenSSL::PKey::EC::Point.new(group, client_public_key_bn)

        shared_secret = server.dh_compute_key(client_public_key)
        client_auth_token = Webpush.decode64(auth)
        info = "WebPush: info\0" + client_public_key_bn.to_s(2) + server_public_key_bn.to_s(2)
        content_encryption_key_info = "Content-Encoding: aes128gcm\0"
        nonce_info = "Content-Encoding: nonce\0"

        prk = HKDF.new(shared_secret, salt: client_auth_token, algorithm: "SHA256", info: info).next_bytes(32)
        content_encryption_key = HKDF.new(prk, salt: salt, info: content_encryption_key_info).next_bytes(16)
        nonce = HKDF.new(prk, salt: salt, info: nonce_info).next_bytes(12)
        ciphertext = encrypt_payload(message, content_encryption_key, nonce)

        serverkey16bn = convert16bit(server_public_key_bn)
        rs = ciphertext.bytesize
        raise ArgumentError, "encrypted payload is too big" if rs > 4096

        salt + [rs].pack("N*") + [serverkey16bn.bytesize].pack("C*") + serverkey16bn + ciphertext
      end
    end
  end
end
