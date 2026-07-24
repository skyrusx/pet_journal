require "test_helper"

class ProductionReadinessTest < ActiveSupport::TestCase
  test "reports missing core production environment" do
    env = {}

    report = PetJournal::ProductionReadiness.report(env)

    assert_includes report[:missing_required_env], "APP_HOST"
    assert_includes report[:missing_required_env], "SECRET_KEY_BASE"
    assert_includes report[:missing_required_env], "DATABASE_URL or PET_JOURNAL_DATABASE_PASSWORD"
  end

  test "accepts database url as database configuration" do
    env = {
      "APP_HOST" => "petjournal.example",
      "SECRET_KEY_BASE" => "secret",
      "DATABASE_URL" => "postgres://postgres:postgres@localhost/pet_journal"
    }

    assert_empty PetJournal::ProductionReadiness.missing_required_env(env)
  end

  test "reports optional notification configuration warnings" do
    env = {
      "APP_HOST" => "petjournal.example",
      "SECRET_KEY_BASE" => "secret",
      "PET_JOURNAL_DATABASE_PASSWORD" => "secret"
    }

    warnings = PetJournal::ProductionReadiness.notification_warnings(env)

    assert warnings.any? { |warning| warning.include?("Email delivery is not configured") }
    assert warnings.any? { |warning| warning.include?("Web Push is not configured") }
    assert warnings.any? { |warning| warning.include?("TELEGRAM_BOT_TOKEN") }
    assert warnings.any? { |warning| warning.include?("VK_GROUP_TOKEN") }
  end
end
