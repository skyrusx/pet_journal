require "test_helper"

class PetsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @pet = pets(:one)
    sign_in @user
  end

  test "should get index" do
    get pets_url

    assert_response :success
    assert_select ".pj-pets-grid"
    assert_select ".pj-pet-list-card", minimum: 1
  end

  test "should progressively load pets in batches of 25" do
    25.times { |index| @user.pets.create!(name: "Питомец #{index + 1}") }

    get pets_url

    assert_response :success
    assert_select ".pj-pet-list-card", count: 25
    assert_select ".pj-pets-load-more", count: 1

    get pets_url(page: 2)

    assert_response :success
    assert_select ".pj-pet-list-card", count: 26
    assert_select ".pj-pets-load-more", count: 0
  end

  test "should show pet" do
    get pet_url(@pet)

    assert_response :success
    assert_select ".pj-pet-profile-page"
    assert_select "form[action='#{pet_path(@pet)}'][onsubmit*='confirm']", count: 2
    assert_select "button[aria-label='Убрать #{@pet.name} из PetJournal']", count: 2
  end

  test "should get new" do
    get new_pet_url

    assert_response :success
  end

  test "should create pet" do
    assert_difference("Pet.count") do
      post pets_url, params: {
        pet: {
          name: "Марс",
          species: "Кот",
          breed: "Метис",
          weight: 4.8
        }
      }
    end

    assert_redirected_to pet_url(Pet.order(:created_at).last)
  end

  test "should get edit" do
    get edit_pet_url(@pet)

    assert_response :success
  end

  test "should update pet" do
    patch pet_url(@pet), params: { pet: { name: "Обновленное имя" } }

    assert_redirected_to pet_url(@pet)
    assert_equal "Обновленное имя", @pet.reload.name
  end

  test "should destroy own pet and associated data" do
    event = @pet.pet_events.create!(event_type: :note, event_date: Date.current, status: :completed)
    reminder = @pet.reminders.create!(title: "Проверить", reminder_type: :other, remind_at: 1.day.from_now, repeat_rule: :once)
    document = @pet.pet_documents.create!(title: "Документ", document_type: :other)
    share = @pet.pet_profile_shares.create!(title: "Для семьи")
    share_view = share.pet_profile_share_views.create!(public_token: SecureRandom.hex(12))
    tag = @pet.pet_tag
    tag_scan = tag.pet_tag_scans.create!
    pet_name = @pet.name

    assert_difference("Pet.count", -1) do
      delete pet_url(@pet)
    end

    assert_redirected_to pets_url
    assert_equal "Профиль #{pet_name} удалён.", flash[:notice]
    refute PetEvent.exists?(event.id)
    refute Reminder.exists?(reminder.id)
    refute PetDocument.exists?(document.id)
    refute PetProfileShare.exists?(share.id)
    refute PetProfileShareView.exists?(share_view.id)
    refute PetTag.exists?(tag.id)
    refute PetTagScan.exists?(tag_scan.id)
  end

  test "should not destroy another users pet" do
    other_pet = pets(:two)

    assert_no_difference("Pet.count") do
      delete pet_url(other_pet)
    end

    assert_response :not_found
    assert Pet.exists?(other_pet.id)
  end
end
