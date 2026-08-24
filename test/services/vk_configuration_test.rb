require "test_helper"

class VkConfigurationTest < ActiveSupport::TestCase
  test "prefers Rails credentials and exposes API version" do
    credentials = {
      vk: {
        group_token: "credential-token",
        api_version: "5.199"
      }
    }

    Rails.application.stub(:credentials, credentials) do
      assert_equal "credential-token", VkConfiguration.group_token
      assert_equal "5.199", VkConfiguration.api_version
      assert VkConfiguration.configured?
    end
  end

  test "falls back to environment and default API version" do
    credentials = { vk: {} }
    previous_token = ENV["VK_GROUP_TOKEN"]
    previous_version = ENV["VK_API_VERSION"]

    ENV["VK_GROUP_TOKEN"] = "env-token"
    ENV.delete("VK_API_VERSION")

    Rails.application.stub(:credentials, credentials) do
      assert_equal "env-token", VkConfiguration.group_token
      assert_equal VkConfiguration::DEFAULT_API_VERSION, VkConfiguration.api_version
    end
  ensure
    previous_token.nil? ? ENV.delete("VK_GROUP_TOKEN") : ENV["VK_GROUP_TOKEN"] = previous_token
    previous_version.nil? ? ENV.delete("VK_API_VERSION") : ENV["VK_API_VERSION"] = previous_version
  end
end
