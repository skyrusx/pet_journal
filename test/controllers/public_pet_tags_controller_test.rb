require "test_helper"

class PublicPetTagsControllerTest < ActionDispatch::IntegrationTest
  test "should show enabled public pet tag" do
    pet_tag = pet_tags(:one)

    get public_pet_tag_url(pet_tag.public_token)

    assert_response :success
    assert_select "h1", pet_tag.pet.name
    assert_select "a[href^='tel:']"
  end

  test "should not show disabled public pet tag" do
    pet_tag = pet_tags(:two)

    get public_pet_tag_url(pet_tag.public_token)

    assert_response :not_found
  end
end
