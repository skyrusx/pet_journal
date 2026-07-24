require "test_helper"

class PetProfileSharesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @pet = pets(:one)
    @share = pet_profile_shares(:one)
    sign_in @user
  end

  test "should get index" do
    get pet_profile_shares_url(@pet)

    assert_response :success
    assert_select "h1", text: "Публичный доступ"
  end

  test "should get new" do
    get new_pet_profile_share_url(@pet)

    assert_response :success
  end

  test "should create profile share with expiration preset" do
    assert_difference("PetProfileShare.count") do
      post pet_profile_shares_url(@pet), params: {
        expires_preset: "thirty_days",
        pet_profile_share: {
          title: "Для передержки",
          detail_level: "full",
          enabled: "1",
          show_profile: "1",
          show_journal: "1",
          show_documents: "1",
          show_reminders: "1",
          show_pet_tag: "0",
          show_owner_contact: "1",
          allow_file_downloads: "1"
        }
      }
    end

    share = PetProfileShare.order(:created_at).last
    assert_redirected_to pet_profile_share_url(@pet, share)
    assert share.detail_full?
    assert share.show_owner_contact?
    assert share.expires_at.present?
  end

  test "should update profile share" do
    patch pet_profile_share_url(@pet, @share), params: {
      expires_preset: "never",
      pet_profile_share: {
        title: "Для семьи",
        detail_level: "brief",
        enabled: "1",
        show_profile: "1",
        show_journal: "0",
        show_documents: "1",
        show_reminders: "0",
        show_pet_tag: "0",
        show_owner_contact: "0",
        allow_file_downloads: "0"
      }
    }

    assert_redirected_to pet_profile_share_url(@pet, @share)
    assert_equal "Для семьи", @share.reload.title
    assert_nil @share.expires_at
    assert_not @share.show_journal?
  end

  test "should disable and enable profile share" do
    patch disable_pet_profile_share_url(@pet, @share)
    assert_redirected_to pet_profile_share_url(@pet, @share)
    assert_not @share.reload.enabled?

    patch enable_pet_profile_share_url(@pet, @share)
    assert_redirected_to pet_profile_share_url(@pet, @share)
    assert @share.reload.enabled?
  end

  test "should rotate public token" do
    old_token = @share.public_token

    patch rotate_token_pet_profile_share_url(@pet, @share)

    assert_redirected_to pet_profile_share_url(@pet, @share)
    assert_not_equal old_token, @share.reload.public_token
    assert @share.token_rotated_at.present?
  end

  test "should download qr svg" do
    get qr_pet_profile_share_url(@pet, @share, format: :svg)

    assert_response :success
    assert_equal "image/svg+xml", response.media_type
  end

  test "should destroy profile share" do
    assert_difference("PetProfileShare.count", -1) do
      delete pet_profile_share_url(@pet, @share)
    end

    assert_redirected_to pet_profile_shares_url(@pet)
  end
end
