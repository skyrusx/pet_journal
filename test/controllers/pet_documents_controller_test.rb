require "test_helper"

class PetDocumentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @pet = pets(:one)
    @document = pet_documents(:passport)
    sign_in @user
  end

  test "should get global index for all pets" do
    second_pet = @user.pets.create!(name: "Луна")
    second_pet.pet_documents.create!(
      document_type: :certificate,
      title: "Справка Луны",
      expiry_reminder_days: 14
    )

    get documents_overview_url

    assert_response :success
    assert_select ".pj-documents-pet-switcher", text: /Все питомцы/
    assert_select ".pj-documents-row__pet", text: second_pet.name
  end

  test "should filter global index by pet" do
    second_pet = @user.pets.create!(name: "Фрея")
    second_pet.pet_documents.create!(document_type: :other, title: "Документ Фреи", expiry_reminder_days: 14)

    get documents_overview_url(pet_id: second_pet.id)

    assert_response :success
    assert_select ".pj-documents-pet-switcher", text: /Фрея/
    assert_select ".pj-documents-row", text: /Документ Фреи/
    assert_select ".pj-documents-row", text: /#{Regexp.escape(@document.title)}/, count: 0
  end

  test "legacy nested index selects requested pet" do
    get pet_pet_documents_url(@pet)

    assert_response :success
    assert_select ".pj-documents-pet-switcher", text: /#{Regexp.escape(@pet.name)}/
  end

  test "should filter by status and type" do
    get documents_overview_url(pet_id: @pet.id, status: "expiring", type: "vaccination")

    assert_response :success
    assert_select "select[name='status'] option[selected='selected'][value='expiring']"
    assert_select "select[name='type'] option[selected='selected'][value='vaccination']"
  end

  test "should filter by files scope" do
    get documents_overview_url(pet_id: @pet.id, scope: "with_files")

    assert_response :success
    assert_select "select[name='scope'] option[selected='selected'][value='with_files']"
  end

  test "should filter by reminder scope" do
    get documents_overview_url(pet_id: @pet.id, scope: "with_reminder")

    assert_response :success
    assert_select "select[name='scope'] option[selected='selected'][value='with_reminder']"
  end

  test "should search documents" do
    get documents_overview_url(pet_id: @pet.id, q: "Ветпаспорт")

    assert_response :success
    assert_select ".pj-documents-row", text: /Ветпаспорт/
  end

  test "should progressively load documents in batches of 25" do
    26.times do |index|
      @pet.pet_documents.create!(
        document_type: :other,
        title: "Документ #{index + 1}",
        expiry_reminder_days: 14
      )
    end

    get documents_overview_url(pet_id: @pet.id)

    assert_response :success
    assert_select ".pj-documents-row-wrap", count: 25
    assert_select ".pj-documents-load-more", count: 1

    get documents_overview_url(pet_id: @pet.id, page: 2)

    assert_response :success
    assert_select ".pj-documents-row-wrap", count: 28
    assert_select ".pj-documents-load-more", count: 0
  end

  test "should get new with save action" do
    get new_pet_pet_document_url(@pet)

    assert_response :success
    assert_select "input[type='submit'][value='Сохранить']"
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

  test "should show standardized document detail" do
    get pet_pet_document_url(@pet, @document)

    assert_response :success
    assert_select ".pj-document-detail-heading--standard", text: /#{Regexp.escape(@document.title)}/
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

  test "should update existing journal event from document" do
    event = @pet.pet_events.create!(event_type: :document, status: :completed, title: "Старое название", event_date: 1.month.ago.to_date)
    @document.update!(pet_event: event, title: "Новое название", issued_on: Date.current)

    assert_no_difference("PetEvent.count") do
      patch sync_journal_event_pet_pet_document_url(@pet, @document)
    end

    assert_equal "Новое название", event.reload.title
    assert_equal Date.current, event.event_date
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

  test "should update existing reminder from document" do
    reminder = @pet.reminders.create!(title: "Старое", reminder_type: :other, remind_at: 1.day.from_now, repeat_rule: :once)
    @document.update!(reminder: reminder, title: "Ветпаспорт 2026", expires_on: 2.months.from_now.to_date, expiry_reminder_days: 7)

    assert_no_difference("Reminder.count") do
      patch sync_expiry_reminder_pet_pet_document_url(@pet, @document)
    end

    assert_equal "Проверить документ: Ветпаспорт 2026", reminder.reload.title
    assert_equal @document.expires_on - 7.days, reminder.next_run_at.to_date
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

  test "should destroy document and return to overview" do
    assert_difference("PetDocument.count", -1) do
      delete pet_pet_document_url(@pet, @document)
    end

    assert_redirected_to documents_overview_url(pet_id: @pet.id)
  end
end
