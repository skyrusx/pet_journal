require "test_helper"

class PetProfileShareTest < ActiveSupport::TestCase
  test "active requires enabled and not expired" do
    assert pet_profile_shares(:one).active?
    assert_not pet_profile_shares(:expired).active?
    assert_not pet_profile_shares(:disabled).active?
  end

  test "requires at least one visible section" do
    share = pets(:one).pet_profile_shares.new(
      title: "Пустой доступ",
      show_profile: false,
      show_journal: false,
      show_documents: false,
      show_reminders: false,
      show_pet_tag: false
    )

    assert_not share.valid?
    assert_includes share.errors[:base], "выберите хотя бы один раздел профиля"
  end
end
