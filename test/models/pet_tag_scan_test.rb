require "test_helper"

class PetTagScanTest < ActiveSupport::TestCase
  test "limits finder supplied text" do
    scan = pet_tags(:one).pet_tag_scans.new(finder_contact: "a" * 161, finder_message: "a" * 1_001)

    assert_not scan.valid?
    assert_includes scan.errors[:finder_contact], "слишком длинное: максимум 160 символов"
    assert_includes scan.errors[:finder_message], "слишком длинное: максимум 1000 символов"
  end
end
