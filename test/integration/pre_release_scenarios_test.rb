require "test_helper"
require "rake"

class PreReleaseScenariosTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in @user
    Rails.application.load_tasks if Rake::Task.tasks.empty?
  end

  test "owner care workflow connects journal reminders documents and dashboard" do
    pet = create_release_pet
    next_action_at = 3.days.from_now.change(sec: 0)

    assert_difference(["PetEvent.count", "Reminder.count"], 1) do
      post pet_pet_events_path(pet), params: {
        create_follow_up_reminder: "1",
        pet_event: {
          event_type: "visit",
          title: "Контрольный прием",
          event_date: Date.current,
          clinic_name: "Release Vet",
          veterinarian_name: "Доктор Релиз",
          next_action_at:
        }
      }
    end

    event = pet.pet_events.order(:created_at).last
    follow_up = pet.reminders.order(:created_at).last

    assert_redirected_to pet_pet_event_path(pet, event)
    assert_equal "Повторить: Контрольный прием", follow_up.title
    assert_equal next_action_at.to_i, follow_up.next_run_at.to_i

    assert_difference(["PetDocument.count", "PetEvent.count", "Reminder.count"], 1) do
      post pet_pet_documents_path(pet), params: {
        create_journal_event: "1",
        create_expiry_reminder: "1",
        pet_document: {
          document_type: "vaccination",
          title: "Справка перед поездкой",
          issuer: "Release Vet",
          number: "REL-001",
          issued_on: Date.current,
          expires_on: 1.month.from_now.to_date,
          expiry_reminder_days: 7
        }
      }
    end

    document = pet.pet_documents.order(:created_at).last
    assert_not_nil document.pet_event
    assert_not_nil document.reminder

    patch complete_pet_reminder_path(pet, follow_up), params: { create_event: "1", completion_note: "Проверено перед релизом" }
    assert_redirected_to pet_reminders_path(pet)
    assert follow_up.reload.status_completed?
    assert follow_up.reminder_completions.last.pet_event.present?

    get pet_path(pet)
    assert_response :success
    assert_match "Справка перед поездкой", response.body
    assert_match "Контрольный прием", response.body
  end

  test "public profile share exposes only selected data and records privacy safe audit" do
    pet = create_release_pet
    pet.pet_documents.create!(
      document_type: "passport",
      title: "Закрытый ветпаспорт",
      issued_on: Date.current,
      expiry_reminder_days: 14
    )
    share = pet.pet_profile_shares.create!(
      title: "Профиль для показа",
      detail_level: :brief,
      show_profile: true,
      show_journal: false,
      show_documents: true,
      show_reminders: false,
      show_pet_tag: false,
      show_owner_contact: false,
      allow_file_downloads: false,
      expires_at: 1.day.from_now
    )

    assert_difference("PetProfileShareView.count", 1) do
      get public_pet_profile_share_path(share.public_token), headers: { "REMOTE_ADDR" => "198.51.100.24" }
      get public_pet_profile_share_path(share.public_token), headers: { "REMOTE_ADDR" => "198.51.100.24" }
    end

    assert_response :success
    assert_equal "noindex, nofollow", response.headers["X-Robots-Tag"]
    assert_match pet.name, response.body
    assert_match "Закрытый ветпаспорт", response.body
    assert_no_match @user.email, response.body
    assert_equal "198.51.100.0", share.pet_profile_share_views.last.ip_address

    patch disable_pet_profile_share_path(pet, share)
    sign_out @user

    get public_pet_profile_share_path(share.public_token)
    assert_response :not_found
  end

  test "pettag lost flow records scan accepts one finder report and notifies owner" do
    pet = create_release_pet
    pet_tag = pet.create_pet_tag!(
      enabled: true,
      public_message: "Если нашли, напишите владельцу.",
      behavior_notes: "Пугливый.",
      medical_notes: "Без срочных лекарств.",
      contact_phone: "+79990000001",
      show_phone: true,
      show_medical_notes: false,
      safety_status: :lost,
      lost_message: "Пожалуйста, свяжитесь сразу.",
      last_seen_location: "Парк",
      notification_preference: :lost_mode
    )

    sign_out @user

    assert_difference("PetTagScan.count", 1) do
      assert_emails 1 do
        get public_pet_tag_path(pet_tag.public_token)
      end
    end

    assert_response :success
    assert_equal "noindex, nofollow", response.headers["X-Robots-Tag"]
    assert_match "Я потерялся", response.body
    assert_no_match "Без срочных лекарств", response.body

    scan = pet_tag.pet_tag_scans.order(:created_at).last

    assert_emails 1 do
      post public_pet_tag_location_path(pet_tag.public_token), params: {
        scan_token: scan.public_token,
        latitude: "53.755833",
        longitude: "87.109167",
        finder_name: "Анна",
        finder_contact: "+79990000002",
        finder_message: "Питомец рядом со мной"
      }
    end

    assert_redirected_to public_pet_tag_path(pet_tag.public_token)
    assert pet_tag.reload.status_found?
    assert scan.reload.status_found_reported?

    assert_no_changes -> { scan.reload.finder_message } do
      post public_pet_tag_location_path(pet_tag.public_token), params: {
        scan_token: scan.public_token,
        finder_message: "Повторная отправка"
      }
    end
  end

  test "release reminder dispatch sends due notification through configured channel" do
    pet = create_release_pet
    Reminder.update_all(last_notified_at: Time.current)
    reminder = pet.reminders.create!(
      title: "Релизная проверка лекарства",
      reminder_type: :medication,
      remind_at: 10.minutes.ago,
      next_run_at: 10.minutes.ago,
      repeat_rule: :once,
      note: "Проверка отправки"
    )
    reminder.notification_channels << notification_channels(:email)
    previous_adapter = ActiveJob::Base.queue_adapter
    ActiveJob::Base.queue_adapter = :inline

    assert_difference("NotificationDelivery.status_sent.count", 1) do
      Rake::Task["reminders:dispatch"].reenable
      Rake::Task["reminders:dispatch"].invoke
    end

    assert_not_nil reminder.reload.last_notified_at
  ensure
    ActiveJob::Base.queue_adapter = previous_adapter if defined?(previous_adapter)
  end

  private

  def create_release_pet
    @user.pets.create!(
      name: "Релиз",
      species: "Кошка",
      breed: "Домашняя",
      sex: :female,
      birth_date: 2.years.ago.to_date,
      weight: 4.2,
      color: "Серый",
      chip_number: "CHIP-REL-001",
      passport_number: "PASS-REL-001"
    )
  end
end
