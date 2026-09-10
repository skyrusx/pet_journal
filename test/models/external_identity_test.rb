require "test_helper"

class ExternalIdentityTest < ActiveSupport::TestCase
  test "provider uid identifies only one PetJournal user" do
    first = ExternalIdentity.create!(
      user: users(:one),
      provider: "vk",
      uid: "vk-user-1",
      connected_at: Time.current
    )

    duplicate = ExternalIdentity.new(
      user: users(:two),
      provider: first.provider,
      uid: first.uid,
      connected_at: Time.current
    )

    assert_not duplicate.valid?
    assert duplicate.errors[:uid].any?
  end

  test "user can have only one identity per provider" do
    user = users(:one)
    ExternalIdentity.create!(user: user, provider: "yandex", uid: "ya-1", connected_at: Time.current)

    duplicate = ExternalIdentity.new(user: user, provider: "yandex", uid: "ya-2", connected_at: Time.current)

    assert_not duplicate.valid?
    assert duplicate.errors[:provider].any?
  end

  test "oauth-only user cannot disconnect the last identity" do
    user = users(:one)
    user.update_column(:password_configured, false)
    identity = ExternalIdentity.create!(user: user, provider: "vk", uid: "vk-only", connected_at: Time.current)

    assert_not user.can_disconnect_external_identity?(identity)

    ExternalIdentity.create!(user: user, provider: "yandex", uid: "ya-backup", connected_at: Time.current)
    assert user.can_disconnect_external_identity?(identity)
  end
end
