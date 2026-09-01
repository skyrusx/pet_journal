require "test_helper"

class ProductionReadinessTest < ActiveSupport::TestCase
  test "reports missing core production environment" do
    env = {}

    report = PetJournal::ProductionReadiness.report(env)

    assert_includes report[:missing_required_env], "APP_HOST"
    assert_includes report[:missing_required_env], "SECRET_KEY_BASE or Rails credentials"
    assert_includes report[:missing_required_env], "DB_CONNECTION_STRING or DATABASE_URL or PET_JOURNAL_DATABASE_PASSWORD"
    assert_includes report[:missing_required_env], "LEGAL_OPERATOR_NAME"
    assert_includes report[:missing_required_env], "LEGAL_OPERATOR_EMAIL"
  end

  test "accepts NetAngels database and legal configuration" do
    env = {
      "APP_HOST" => "petjournal.example",
      "SECRET_KEY_BASE" => "secret",
      "DB_CONNECTION_STRING" => "postgres://postgres:postgres@localhost/pet_journal",
      "LEGAL_OPERATOR_NAME" => "PetJournal Test Operator",
      "LEGAL_OPERATOR_EMAIL" => "privacy@example.test"
    }

    assert_empty PetJournal::ProductionReadiness.missing_required_env(env)
  end

  test "accepts secret key base from Rails credentials" do
    env = {
      "APP_HOST" => "petjournal.example",
      "DB_CONNECTION_STRING" => "postgres://postgres:postgres@localhost/pet_journal",
      "LEGAL_OPERATOR_NAME" => "PetJournal Test Operator",
      "LEGAL_OPERATOR_EMAIL" => "privacy@example.test"
    }

    assert_empty PetJournal::ProductionReadiness.missing_required_env(env, secret_key_base: "credentials-secret")
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

  test "accepts VAPID environment configuration for Web Push" do
    env = {
      "VAPID_PUBLIC_KEY" => "public-key",
      "VAPID_PRIVATE_KEY" => "private-key"
    }

    warnings = PetJournal::ProductionReadiness.notification_warnings(env)

    assert_not warnings.any? { |warning| warning.include?("Web Push is not configured") }
  end
end
