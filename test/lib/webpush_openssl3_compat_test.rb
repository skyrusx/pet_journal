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
end
