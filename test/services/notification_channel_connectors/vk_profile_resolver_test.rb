require "test_helper"

class NotificationChannelConnectors::VkProfileResolverTest < ActiveSupport::TestCase
  test "normalizes common VK profile inputs" do
    resolver = NotificationChannelConnectors::VkProfileResolver

    assert_equal "skyrusx", resolver.normalize("https://vk.ru/skyrusx")
    assert_equal "skyrusx", resolver.normalize("vk.com/skyrusx/")
    assert_equal "skyrusx", resolver.normalize("@skyrusx")
    assert_equal "123456", resolver.normalize("id123456")
    assert_equal "123456", resolver.normalize("123456")
  end
end
