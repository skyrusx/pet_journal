require "test_helper"

class LegalLinksHelperTest < ActionView::TestCase
  include LegalLinksHelper

  test "uses canonical legal link labels" do
    assert_equal "Политика конфиденциальности", legal_link_label(:privacy)
    assert_equal "Согласие на обработку персональных данных", legal_link_label(:personal_data_consent)
    assert_equal "Согласие на обработку данных отправителя PetTag", legal_link_label(:pet_tag_data_consent)
    assert_equal "Согласие на публикацию телефона в PetTag", legal_link_label(:pet_tag_phone_distribution_consent)
  end

  test "can lowercase canonical labels for inline sentences" do
    assert_equal "согласие на обработку персональных данных",
                 legal_link_label(:personal_data_consent, lowercase: true)
    assert_equal "согласие на обработку данных отправителя PetTag",
                 legal_link_label(:pet_tag_data_consent, lowercase: true)
  end

  test "adds canonical legal link class and preserves custom classes" do
    html = legal_link(:privacy, class: "active")

    assert_includes html, 'class="pj-legal-link active"'
  end
end
