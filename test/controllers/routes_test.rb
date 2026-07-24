require "test_helper"

class RoutesTest < ActionDispatch::IntegrationTest
  test "does not expose scaffold pet event routes" do
    get "/pet_events/create"
    assert_response :not_found

    get "/pet_events/update"
    assert_response :not_found

    get "/pet_events/destroy"
    assert_response :not_found
  end
end
