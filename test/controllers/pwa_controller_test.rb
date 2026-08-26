require "test_helper"

class PwaControllerTest < ActionDispatch::IntegrationTest
  test "manifest contains production install metadata" do
    get pwa_manifest_path(format: :json)

    assert_response :success
    manifest = JSON.parse(response.body)

    assert_equal "PetJournal", manifest.fetch("name")
    assert_equal "/", manifest.fetch("id")
    assert_equal "/", manifest.fetch("start_url")
    assert_equal "/", manifest.fetch("scope")
    assert_equal "standalone", manifest.fetch("display")
    assert_equal false, manifest.fetch("prefer_related_applications")

    icon_sizes = manifest.fetch("icons").map { |icon| icon.fetch("sizes") }
    assert_includes icon_sizes, "192x192"
    assert_includes icon_sizes, "512x512"
    assert manifest.fetch("icons").any? { |icon| icon["purpose"] == "maskable" }

    shortcut_urls = manifest.fetch("shortcuts").map { |shortcut| shortcut.fetch("url") }
    assert_includes shortcut_urls, "/pets"
    assert_includes shortcut_urls, "/journal"
    assert_includes shortcut_urls, "/reminders"
    assert_includes shortcut_urls, "/documents"
  end

  test "service worker provides privacy safe offline fallback" do
    get pwa_service_worker_path

    assert_response :success
    assert_includes response.body, 'const OFFLINE_URL = "/offline.html"'
    assert_includes response.body, 'request.mode === "navigate"'
    assert_includes response.body, 'url.pathname.startsWith("/assets/")'
    assert_not_includes response.body, "cache.put(request, response.clone());\n  }\n  return response;\n}\n\nasync function navigationResponse"
  end

  test "application shell advertises standalone metadata" do
    get root_path

    assert_response :success
    assert_select 'html[lang="ru"]'
    assert_select 'link[rel="manifest"]', count: 1
    assert_select 'meta[name="theme-color"][content="#07392f"]', count: 1
    assert_select 'meta[name="mobile-web-app-capable"][content="yes"]', count: 1
    assert_select 'meta[name="apple-mobile-web-app-capable"][content="yes"]', count: 1
    assert_select 'meta[name="apple-mobile-web-app-status-bar-style"][content="black-translucent"]', count: 1
  end
end
