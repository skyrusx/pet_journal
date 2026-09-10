require "test_helper"
require "uri"
require "cgi"

class OauthProviderTest < ActiveSupport::TestCase
  setup do
    @old_vk_client_id = ENV["VK_CLIENT_ID"]
    @old_yandex_client_id = ENV["YANDEX_CLIENT_ID"]
    @old_yandex_client_secret = ENV["YANDEX_CLIENT_SECRET"]
    ENV["VK_CLIENT_ID"] = "vk-app"
    ENV["YANDEX_CLIENT_ID"] = "ya-app"
    ENV["YANDEX_CLIENT_SECRET"] = "ya-secret"
  end

  teardown do
    restore_env("VK_CLIENT_ID", @old_vk_client_id)
    restore_env("YANDEX_CLIENT_ID", @old_yandex_client_id)
    restore_env("YANDEX_CLIENT_SECRET", @old_yandex_client_secret)
  end

  test "vk authorization URL uses state and PKCE" do
    provider = Oauth::VkProvider.new(redirect_uri: "https://pet-journal.test/oauth/vk/callback")
    query = query_for(provider.authorization_url(state: "state-1", code_challenge: "challenge-1"))

    assert_equal "vk-app", query["client_id"]
    assert_equal "vk-app", query["app_id"]
    assert_equal "code", query["response_type"]
    assert_equal "state-1", query["state"]
    assert_equal "challenge-1", query["code_challenge"]
    assert_equal "s256", query["code_challenge_method"]
    assert_equal "email phone", query["scope"]
  end

  test "yandex authorization URL uses state and PKCE" do
    provider = Oauth::YandexProvider.new(redirect_uri: "https://pet-journal.test/oauth/yandex/callback")
    query = query_for(provider.authorization_url(state: "state-2", code_challenge: "challenge-2"))

    assert_equal "ya-app", query["client_id"]
    assert_equal "code", query["response_type"]
    assert_equal "state-2", query["state"]
    assert_equal "challenge-2", query["code_challenge"]
    assert_equal "S256", query["code_challenge_method"]
  end

  private

  def query_for(url)
    CGI.parse(URI(url).query).transform_values(&:first)
  end

  def restore_env(name, value)
    value.nil? ? ENV.delete(name) : ENV[name] = value
  end
end
