require "test_helper"

class PublicPetTagsControllerTest < ActionDispatch::IntegrationTest
  test "should show enabled public pet tag" do
    pet_tag = pet_tags(:one)

    assert_difference("PetTagScan.count") do
      get public_pet_tag_url(pet_tag.public_token)
    end

    assert_response :success
    assert_select "h1", pet_tag.pet.name
    assert_select "a[href^='tel:']"
  end

  test "should throttle repeated scans in same session" do
    pet_tag = pet_tags(:one)

    assert_difference("PetTagScan.count", 1) do
      get public_pet_tag_url(pet_tag.public_token)
      get public_pet_tag_url(pet_tag.public_token)
    end
  end

  test "should show lost mode state" do
    pet_tag = pet_tags(:one)

    get public_pet_tag_url(pet_tag.public_token)

    assert_response :success
    assert_select ".lost-mode-banner", text: "Я потерялся"
    assert_select ".lost-mode-message", text: /#{Regexp.escape(pet_tag.lost_message)}/
    assert_select ".last-seen", text: /#{Regexp.escape(pet_tag.last_seen_location)}/
  end

  test "should send scan notification in lost mode" do
    pet_tag = pet_tags(:one)

    assert_emails 1 do
      get public_pet_tag_url(pet_tag.public_token)
    end
  end

  test "should save voluntary location" do
    pet_tag = pet_tags(:one)
    get public_pet_tag_url(pet_tag.public_token)
    scan_token = PetTagScan.order(:created_at).last.public_token

    assert_emails 1 do
      post public_pet_tag_location_url(pet_tag.public_token), params: {
        scan_token: scan_token,
        latitude: "53.755833",
        longitude: "87.109167",
        location_note: "У входа"
      }
    end

    scan = PetTagScan.find_by!(public_token: scan_token)
    assert_redirected_to public_pet_tag_url(pet_tag.public_token)
    assert scan.location_shared?
    assert_equal "У входа", scan.location_note
  end

  test "should not show disabled public pet tag" do
    pet_tag = pet_tags(:two)

    get public_pet_tag_url(pet_tag.public_token)

    assert_response :not_found
  end
end
