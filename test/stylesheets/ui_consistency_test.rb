require "test_helper"

class UiConsistencyTest < ActiveSupport::TestCase
  TOKENS_PATH = Rails.root.join("app/assets/stylesheets/petjournal/_tokens.scss")
  CONSISTENCY_PATH = Rails.root.join("app/assets/stylesheets/petjournal/_ui_consistency.scss")
  APPLICATION_PATH = Rails.root.join("app/assets/stylesheets/application.scss")

  test "canonical UI consistency layer is the final PetJournal stylesheet import" do
    imports = File.readlines(APPLICATION_PATH, chomp: true)
                  .map(&:strip)
                  .select { |line| line.start_with?("@import \"petjournal/") }

    assert_equal '@import "petjournal/ui_consistency";', imports.last
  end

  test "canonical sizing tokens are present" do
    tokens = File.read(TOKENS_PATH)

    %w[
      --pj-font-caption
      --pj-font-meta
      --pj-font-body
      --pj-font-topbar-title
      --pj-font-section-title
      --pj-font-detail-title
      --pj-font-page-title
      --pj-size-topbar
      --pj-size-control
      --pj-size-control-lg
      --pj-size-touch-target
      --pj-workspace-page-side
      --pj-radius-control
      --pj-radius-card
      --pj-radius-panel
    ].each do |token|
      assert_includes tokens, token, "missing canonical UI token #{token}"
    end
  end

  test "canonical layer does not introduce hardcoded typography or radii" do
    css = File.read(CONSISTENCY_PATH)

    assert_no_match(/font-size:\s*\d+(?:\.\d+)?px\b/, css)
    assert_no_match(/border-radius:\s*\d+(?:\.\d+)?px\b/, css)
  end
end
