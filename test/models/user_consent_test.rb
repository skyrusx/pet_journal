require "test_helper"

class UserConsentTest < ActiveSupport::TestCase
  test "accepts one active consent per user type and document version" do
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

  test "allows a new acceptance after previous consent is revoked" do
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
end
