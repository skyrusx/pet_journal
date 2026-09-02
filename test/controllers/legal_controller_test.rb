require "test_helper"

class LegalControllerTest < ActionDispatch::IntegrationTest
  test "privacy policy is public, versioned and uses landing shell" do
    get privacy_path

    assert_response :success
    assert_select ".pj-new-design.pj-legal-page"
    assert_select "header.pj-nd-navbar" do
      assert_select ".pj-nd-shell"
      assert_select "a[href=?]", root_path(anchor: "features"), text: "Возможности"
      assert_select "a[href=?]", root_path(anchor: "how-it-works"), text: "Как это работает"
    end
    assert_select ".pj-legal-main > .pj-nd-shell"
    assert_select "footer.pj-nd-footer > .pj-nd-shell"
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

  test "PetTag finder consent is public and separate" do
    get pet_tag_data_consent_path

    assert_response :success
    assert_select "h1", text: "Согласие на обработку персональных данных отправителя PetTag"
    assert_select ".pj-legal-meta", text: /Версия #{Regexp.escape(LegalDocuments.version(:pet_tag_finder_consent))}/
    assert_select "a[href=?]", privacy_path
  end

  test "PetTag phone distribution consent is public and versioned" do
    get pet_tag_phone_distribution_consent_path

    assert_response :success
    assert_select "h1", text: "Согласие на обработку персональных данных, разрешённых для распространения через PetTag"
    assert_select ".pj-legal-meta", text: /Версия #{Regexp.escape(LegalDocuments.version(:pet_tag_phone_distribution_consent))}/
    assert_select "a[href=?]", privacy_path
    assert_match(/номер телефона/, response.body)
  end
end
