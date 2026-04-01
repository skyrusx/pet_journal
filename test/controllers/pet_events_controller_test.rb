require "test_helper"

class PetEventsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get pet_events_index_url
    assert_response :success
  end

  test "should get show" do
    get pet_events_show_url
    assert_response :success
  end

  test "should get new" do
    get pet_events_new_url
    assert_response :success
  end

  test "should get create" do
    get pet_events_create_url
    assert_response :success
  end

  test "should get edit" do
    get pet_events_edit_url
    assert_response :success
  end

  test "should get update" do
    get pet_events_update_url
    assert_response :success
  end

  test "should get destroy" do
    get pet_events_destroy_url
    assert_response :success
  end
end
