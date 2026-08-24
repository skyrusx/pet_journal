require "test_helper"

class WebpushOpenssl3CompatTest < ActiveSupport::TestCase
  test "generates and rebuilds VAPID keys" do
    key = Webpush.generate_key

    assert key.public_key.present?
    assert key.private_key.present?

    rebuilt = Webpush::VapidKey.from_keys(key.public_key, key.private_key)

    assert_equal key.public_key, rebuilt.public_key
    assert_equal key.private_key, rebuilt.private_key
  end

  test "encrypts a push payload without mutating an EC key" do
    client_key = OpenSSL::PKey::EC.generate("prime256v1")
    p256dh = Webpush.encode64(client_key.public_key.to_bn.to_s(2))
    auth = Webpush.encode64(SecureRandom.random_bytes(16))

    encrypted = Webpush::Encryption.encrypt("PetJournal test", p256dh, auth)

    assert encrypted.present?
    assert_operator encrypted.bytesize, :>, "PetJournal test".bytesize
  end
end
