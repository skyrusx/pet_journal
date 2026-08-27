require "test_helper"

class PublicPetTagsControllerTest < ActionDispatch::IntegrationTest
  test "shows enabled public PetTag without human owner contacts" do
    pet_tag = pet_tags(:one)
    owner = pet_tag.pet.user

    assert_difference("PetTagScan.count") do
      get public_pet_tag_url(pet_tag.public_token)
    end

    assert_response :success
    assert_select ".pj-public-tag-pet-card h2", text: pet_tag.pet.name
    assert_select "a[href^='tel:']", count: 0
    assert_no_match Regexp.new(Regexp.escape(owner.email)), response.body
    assert_no_match Regexp.new(Regexp.escape(owner.name)), response.body if owner.name.present?
    assert_equal "noindex, nofollow", response.headers["X-Robots-Tag"]
  end

  test "does not persist browser fingerprinting fields for a plain scan" do
    pet_tag = pet_tags(:one)

    get public_pet_tag_url(pet_tag.public_token), headers: {
      "User-Agent" => "PetJournal test scanner",
      "Referer" => "https://example.test/source"
    }

    scan = pet_tag.pet_tag_scans.order(:created_at).last
    assert_nil scan.user_agent
    assert_nil scan.referrer
  end

  test "shows separate finder consent and privacy links" do
    pet_tag = pet_tags(:one)

    get public_pet_tag_url(pet_tag.public_token)

    assert_response :success
    assert_select "input[name='finder_personal_data_consent'][type='checkbox'][required]", count: 1
    assert_select "a[href=?]", pet_tag_data_consent_path
    assert_select "a[href=?]", privacy_path
  end

  test "throttles repeated scans in same session" do
    pet_tag = pet_tags(:one)

    assert_difference("PetTagScan.count", 1) do
      get public_pet_tag_url(pet_tag.public_token)
      get public_pet_tag_url(pet_tag.public_token)
    end
  end

  test "shows lost mode state" do
    pet_tag = pet_tags(:one)

    get public_pet_tag_url(pet_tag.public_token)

    assert_response :success
    assert_select ".pj-public-tag-alert", text: /#{Regexp.escape(pet_tag.lost_message)}/
    assert_select ".pj-public-tag-alert", text: /#{Regexp.escape(pet_tag.last_seen_location)}/
  end

  test "sends scan notification in lost mode" do
    pet_tag = pet_tags(:one)

    assert_emails 1 do
      get public_pet_tag_url(pet_tag.public_token)
    end
  end

  test "rejects finder data without separate consent" do
    pet_tag = pet_tags(:one)
    get public_pet_tag_url(pet_tag.public_token)
    scan = pet_tag.pet_tag_scans.order(:created_at).last

    assert_no_changes -> { scan.reload.finder_message } do
      post public_pet_tag_location_url(pet_tag.public_token), params: {
        scan_token: scan.public_token,
        finder_name: "Анна",
        finder_contact: "+79990000002",
        finder_message: "Питомец со мной"
      }
    end

    assert_redirected_to public_pet_tag_url(pet_tag.public_token, anchor: "found-form")
    assert_nil scan.reload.finder_consented_at
  end

  test "saves voluntary finder data with consent evidence" do
    pet_tag = pet_tags(:one)
    get public_pet_tag_url(pet_tag.public_token)
    scan_token = PetTagScan.order(:created_at).last.public_token

    assert_emails 1 do
      post public_pet_tag_location_url(pet_tag.public_token), params: {
        scan_token: scan_token,
        finder_personal_data_consent: "1",
        latitude: "53.755833",
        longitude: "87.109167",
        location_note: "У входа",
        finder_name: "Анна",
        finder_contact: "+79990000002",
        finder_message: "Питомец со мной"
      }
    end

    scan = PetTagScan.find_by!(public_token: scan_token)
    assert_redirected_to public_pet_tag_url(pet_tag.public_token)
    assert scan.location_shared?
    assert scan.status_found_reported?
    assert_equal "У входа", scan.location_note
    assert_equal "Анна", scan.finder_name
    assert_equal "+79990000002", scan.finder_contact
    assert_equal "Питомец со мной", scan.finder_message
    assert_equal LegalDocuments.version(:pet_tag_finder_consent), scan.finder_consent_version
    assert_equal LegalDocuments.version(:privacy_policy), scan.finder_privacy_policy_version
    assert scan.finder_consented_at.present?
    assert pet_tag.reload.status_found?
  end

  test "does not accept finder data for scan from another session" do
    pet_tag = pet_tags(:one)
    scan = pet_tag.pet_tag_scans.create!

    assert_no_changes -> { scan.reload.finder_message } do
      post public_pet_tag_location_url(pet_tag.public_token), params: {
        scan_token: scan.public_token,
        finder_personal_data_consent: "1",
        finder_message: "Попытка без сессии"
      }
    end

    assert_response :not_found
  end

  test "does not overwrite already shared finder data" do
    pet_tag = pet_tags(:one)
    get public_pet_tag_url(pet_tag.public_token)
    scan = PetTagScan.order(:created_at).last

    post public_pet_tag_location_url(pet_tag.public_token), params: {
      scan_token: scan.public_token,
      finder_personal_data_consent: "1",
      finder_message: "Первое сообщение"
    }

    assert_no_changes -> { scan.reload.finder_message } do
      post public_pet_tag_location_url(pet_tag.public_token), params: {
        scan_token: scan.public_token,
        finder_personal_data_consent: "1",
        finder_message: "Перезапись"
      }
    end

    assert_redirected_to public_pet_tag_url(pet_tag.public_token)
  end

  test "hides medical notes when disabled" do
    pet_tag = pet_tags(:one)
    pet_tag.update!(show_medical_notes: false)

    get public_pet_tag_url(pet_tag.public_token)

    assert_response :success
    assert_no_match(/Важно для здоровья/, response.body)
  end

  test "does not show disabled public PetTag" do
    pet_tag = pet_tags(:two)

    get public_pet_tag_url(pet_tag.public_token)

    assert_response :not_found
  end
end
