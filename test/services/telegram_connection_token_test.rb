require "test_helper"

class TelegramConnectionTokenTest < ActiveSupport::TestCase
  test "resolves a fresh token to its user" do
    user = users(:one)
    issued_at = Time.utc(2026, 8, 22, 5, 0, 0)

    token = TelegramConnectionToken.generate(user, issued_at: issued_at)

    assert_equal user, TelegramConnectionToken.resolve(token, now: issued_at + 5.minutes)
    assert_operator token.length, :<=, 64
  end

  test "rejects an expired token" do
    user = users(:one)
    issued_at = Time.utc(2026, 8, 22, 5, 0, 0)
    token = TelegramConnectionToken.generate(user, issued_at: issued_at)

    assert_raises(TelegramConnectionToken::InvalidToken) do
      TelegramConnectionToken.resolve(token, now: issued_at + 31.minutes)
    end
  end

  test "rejects a modified token" do
    user = users(:one)
    issued_at = Time.utc(2026, 8, 22, 5, 0, 0)
    token = TelegramConnectionToken.generate(user, issued_at: issued_at)

    assert_raises(TelegramConnectionToken::InvalidToken) do
      TelegramConnectionToken.resolve("#{token}x", now: issued_at + 1.minute)
    end
  end
end
