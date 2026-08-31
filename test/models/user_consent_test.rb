require "test_helper"

class UserConsentTest < ActiveSupport::TestCase
  test "accepts one active global consent per user type and document version" do
    user = users(:one)
    attributes = {
      consent_type: UserConsent::PERSONAL_DATA,
      document_version: LegalDocuments.version(:personal_data_consent),
      accepted_at: Time.current,
      source: "registration"
    }

    user.user_consents.create!(attributes)
    duplicate = user.user_consents.new(attributes)

    assert_not duplicate.valid?
    assert duplicate.errors[:consent_type].any?
  end

  test "allows a new global acceptance after previous consent is revoked" do
    user = users(:one)
    accepted_at = 2.days.ago
    consent = user.user_consents.create!(
      consent_type: UserConsent::PERSONAL_DATA,
      document_version: LegalDocuments.version(:personal_data_consent),
      accepted_at: accepted_at,
      source: "registration"
    )
    consent.update!(revoked_at: 1.day.ago)

    replacement = user.user_consents.new(
      consent_type: UserConsent::PERSONAL_DATA,
      document_version: LegalDocuments.version(:personal_data_consent),
      accepted_at: Time.current,
      source: "registration"
    )

    assert replacement.valid?
  end

  test "allows separate active PetTag phone consents for different PetTags" do
    user = users(:one)
    first_tag = pet_tags(:one)
    second_pet = user.pets.create!(name: "Второй питомец")
    second_tag = second_pet.create_pet_tag!(contact_phone: "+79990000009")

    [first_tag, second_tag].each do |pet_tag|
      user.user_consents.create!(
        consentable: pet_tag,
        consent_type: UserConsent::PET_TAG_PHONE_DISTRIBUTION,
        document_version: LegalDocuments.version(:pet_tag_phone_distribution_consent),
        accepted_at: Time.current,
        source: "pet_tag_settings",
        metadata: distribution_metadata(pet_tag, user)
      )
    end

    assert_equal 2, user.user_consents.active.where(consent_type: UserConsent::PET_TAG_PHONE_DISTRIBUTION).count
  end

  test "requires PetTag scope for phone distribution consent" do
    consent = users(:one).user_consents.new(
      consent_type: UserConsent::PET_TAG_PHONE_DISTRIBUTION,
      document_version: LegalDocuments.version(:pet_tag_phone_distribution_consent),
      accepted_at: Time.current,
      source: "pet_tag_settings",
      metadata: distribution_metadata(pet_tags(:one), users(:one))
    )

    assert_not consent.valid?
    assert consent.errors[:consentable].any?
  end

  test "requires complete evidence metadata for phone distribution consent" do
    consent = users(:one).user_consents.new(
      consentable: pet_tags(:one),
      consent_type: UserConsent::PET_TAG_PHONE_DISTRIBUTION,
      document_version: LegalDocuments.version(:pet_tag_phone_distribution_consent),
      accepted_at: Time.current,
      source: "pet_tag_settings",
      metadata: { "phone" => pet_tags(:one).contact_phone }
    )

    assert_not consent.valid?
    assert consent.errors[:metadata].any?
  end

  private

  def distribution_metadata(pet_tag, user)
    {
      "subject_full_name" => "Иванов Иван Иванович",
      "subject_contact" => user.email,
      "phone" => pet_tag.contact_phone,
      "pet_tag_id" => pet_tag.id,
      "pet_tag_code" => pet_tag.tag_code,
      "public_token" => pet_tag.public_token,
      "public_resource_url" => "https://example.test#{pet_tag.public_path}",
      "purpose" => PetTag::PHONE_DISTRIBUTION_PURPOSE,
      "conditions" => PetTag::PHONE_DISTRIBUTION_CONDITIONS,
      "operator_name" => LegalOperatorConfiguration.name,
      "operator_email" => LegalOperatorConfiguration.email
    }
  end
end
