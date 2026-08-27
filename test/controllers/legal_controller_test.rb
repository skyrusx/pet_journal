require "test_helper"

class LegalControllerTest < ActionDispatch::IntegrationTest
  test "privacy policy is public and versioned" do
    get privacy_path

    assert_response :success
    assert_select "h1", text: "Политика в отношении обработки персональных данных"
    assert_select ".pj-legal-meta", text: /Версия #{Regexp.escape(LegalDocuments.version(:privacy_policy))}/
    assert_select "a[href=?]", personal_data_consent_path
  end

  test "personal data consent is public and separate" do
    get personal_data_consent_path

    assert_response :success
    assert_select "h1", text: "Согласие на обработку персональных данных"
    assert_select ".pj-legal-meta", text: /Версия #{Regexp.escape(LegalDocuments.version(:personal_data_consent))}/
    assert_select "a[href=?]", privacy_path
  end
end
