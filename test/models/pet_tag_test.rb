require "test_helper"

class PetTagTest < ActiveSupport::TestCase
  test "limits public text fields" do
    tag = pet_tags(:one)
    tag.public_message = "a" * 501
    tag.behavior_notes = "a" * 1_001

    assert_not tag.valid?
    assert_includes tag.errors[:public_message], "слишком длинное: максимум 500 символов"
    assert_includes tag.errors[:behavior_notes], "слишком длинное: максимум 1000 символов"
  end
end
