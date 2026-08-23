require "test_helper"

class PublicPetProfileSharesControllerTest < ActionDispatch::IntegrationTest
  test "should show active public profile share and record view" do
    share = pet_profile_shares(:one)

    assert_difference("PetProfileShareView.count") do
      get public_pet_profile_share_url(share.public_token)
    end

    assert_response :success
    assert_select "h1", text: share.pet.name
    assert_select ".public-share-section", minimum: 1
    assert_select 'a.pj-public-profile-share-button[href="#public-share-sheet"]', text: /Поделиться/
    assert_select '#public-share-sheet.pj-public-share-sheet' do
      assert_select "h2", text: "Поделиться профилем"
      assert_select 'a[href^="https://t.me/share/url?"]', text: "Telegram"
      assert_select 'a[href^="https://vk.com/share.php?"]', text: "ВКонтакте"
      assert_select 'a[href^="mailto:?"]', text: "Почта"
      assert_select 'input[readonly][value=?]', public_pet_profile_share_url(share.public_token)
    end
    assert share.reload.last_viewed_at.present?
    assert_equal "noindex, nofollow", response.headers["X-Robots-Tag"]
  end

  test "should throttle repeated public profile views in same session" do
    share = pet_profile_shares(:one)

    assert_difference("PetProfileShareView.count", 1) do
      get public_pet_profile_share_url(share.public_token)
      get public_pet_profile_share_url(share.public_token)
    end
  end

  test "should store anonymized viewer ip" do
    share = pet_profile_shares(:one)

    get public_pet_profile_share_url(share.public_token), headers: { "REMOTE_ADDR" => "203.0.113.42" }

    assert_response :success
    assert_equal "203.0.113.0", share.pet_profile_share_views.order(:created_at).last.ip_address
  end

  test "should not show expired public profile share" do
    get public_pet_profile_share_url(pet_profile_shares(:expired).public_token)

    assert_response :not_found
  end

  test "should not show disabled public profile share" do
    get public_pet_profile_share_url(pet_profile_shares(:disabled).public_token)

    assert_response :not_found
  end

  test "should hide owner contact when disabled" do
    get public_pet_profile_share_url(pet_profile_shares(:one).public_token)

    assert_response :success
    assert_no_match users(:one).email, response.body
  end
end
