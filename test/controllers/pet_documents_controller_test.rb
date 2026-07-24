require "test_helper"

class PetDocumentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @pet = pets(:one)
    @document = pet_documents(:passport)
    sign_in @user
  end

  test "should get index" do
    get pet_pet_documents_url(@pet)

    assert_response :success
    assert_select ".documents-hero"
    assert_select ".documents-filter-panel"
    assert_select ".documents-metrics > div", count: 5
  end

  test "should filter by status and type" do
    get pet_pet_documents_url(@pet, status: "expiring", type: "vaccination")

    assert_response :success
    assert_select ".filter-chip.active", text: /Скоро истекают/
    assert_select ".filter-chip.active", text: /Прививка/
  end

  test "should filter by files scope" do
    get pet_pet_documents_url(@pet, scope: "with_files")

    assert_response :success
    assert_select ".filter-chip.active", text: /С файлами/
  end

  test "should filter by reminder scope" do
    get pet_pet_documents_url(@pet, scope: "with_reminder")

    assert_response :success
    assert_select ".filter-chip.active", text: /С напоминанием/
  end

  test "should search documents" do
    get pet_pet_documents_url(@pet, q: "Ветпаспорт")

    assert_response :success
    assert_select "h3", text: /Ветпаспорт/
  end

  test "should get new" do
    get new_pet_pet_document_url(@pet)

    assert_response :success
  end

  test "should create document with journal event and reminder" do
    assert_difference(["PetDocument.count", "PetEvent.count", "Reminder.count"]) do
      post pet_pet_documents_url(@pet), params: {
        create_journal_event: "1",
        create_expiry_reminder: "1",
        pet_document: {
          document_type: "vaccination",
          title: "Новая прививка",
          issuer: "Клиника",
          number: "VAC-2026",
          issued_on: Date.current,
          expires_on: 1.year.from_now.to_date,
          expiry_reminder_days: 30,
          notes: "Плановая ревакцинация"
        }
      }
    end

    document = PetDocument.order(:created_at).last
    assert_redirected_to pet_pet_document_url(@pet, document)
    assert_not_nil document.pet_event
    assert_not_nil document.reminder
  end

  test "should show document" do
    get pet_pet_document_url(@pet, @document)

    assert_response :success
  end

  test "should sync journal event from document" do
    document = @pet.pet_documents.create!(
      document_type: "certificate",
      title: "Справка для поездки",
      issued_on: Date.current,
      expiry_reminder_days: 14
    )

    assert_difference("PetEvent.count") do
      patch sync_journal_event_pet_pet_document_url(@pet, document)
    end

    assert_redirected_to pet_pet_document_url(@pet, document)
    assert_equal "Справка для поездки", document.reload.pet_event.title
  end

  test "should sync expiry reminder from document" do
    document = @pet.pet_documents.create!(
      document_type: "vaccination",
      title: "Вакцинация бешенство",
      issued_on: Date.current,
      expires_on: 1.year.from_now.to_date,
      expiry_reminder_days: 30
    )

    assert_difference("Reminder.count") do
      patch sync_expiry_reminder_pet_pet_document_url(@pet, document)
    end

    assert_redirected_to pet_pet_document_url(@pet, document)
    assert_equal "Проверить документ: Вакцинация бешенство", document.reload.reminder.title
    assert_equal "vaccination", document.reminder.reminder_type
  end

  test "should not sync expiry reminder without expiry date" do
    document = @pet.pet_documents.create!(
      document_type: "other",
      title: "Бессрочный документ",
      expiry_reminder_days: 14
    )

    assert_no_difference("Reminder.count") do
      patch sync_expiry_reminder_pet_pet_document_url(@pet, document)
    end

    assert_redirected_to pet_pet_document_url(@pet, document)
    assert_nil document.reload.reminder
  end

  test "should update document" do
    patch pet_pet_document_url(@pet, @document), params: {
      pet_document: {
        title: "Обновленный ветпаспорт",
        document_type: @document.document_type,
        expiry_reminder_days: @document.expiry_reminder_days
      }
    }

    assert_redirected_to pet_pet_document_url(@pet, @document)
    assert_equal "Обновленный ветпаспорт", @document.reload.title
  end

  test "should destroy document" do
    assert_difference("PetDocument.count", -1) do
      delete pet_pet_document_url(@pet, @document)
    end

    assert_redirected_to pet_pet_documents_url(@pet)
  end
end
