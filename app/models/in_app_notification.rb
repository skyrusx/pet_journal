class InAppNotification < ApplicationRecord
  belongs_to :user

  validates :kind, :title, :source_key, :occurred_at, presence: true
  validates :source_key, uniqueness: { scope: :user_id }

  scope :recent, -> { order(occurred_at: :desc, id: :desc) }
  scope :unread, -> { where(read_at: nil) }

  def read?
    read_at.present?
  end

  def mark_read!
    update!(read_at: Time.current) unless read?
  end

  def self.for_reminder!(reminder)
    occurrence = reminder.next_run_at
    user = reminder.user
    zone = user.notifications_time_zone_name
    local_time = occurrence.in_time_zone(zone)
    today = Time.current.in_time_zone(zone).to_date
    day_label = if local_time.to_date == today
      "Сегодня"
    elsif local_time.to_date == today + 1.day
      "Завтра"
    else
      local_time.strftime("%d.%m.%Y")
    end

    create_or_find_by!(user:, source_key: "reminder:#{reminder.id}:#{occurrence.to_i}") do |notification|
      notification.kind = "reminder_due"
      notification.title = "Пора: #{reminder.title}"
      notification.body = [reminder.pet.name, "#{day_label}, #{local_time.strftime('%H:%M')}", reminder.reminder_type_label].join(" • ")
      notification.target_path = Rails.application.routes.url_helpers.pet_reminder_path(reminder.pet, reminder)
      notification.occurred_at = occurrence
      notification.metadata = {
        "reminder_id" => reminder.id,
        "pet_id" => reminder.pet_id,
        "note" => reminder.note
      }
    end
  end

  def self.for_pet_tag_scan!(scan, event:)
    pet = scan.pet_tag.pet
    user = pet.user
    kind = event.to_s == "found" ? "pet_tag_found" : "pet_tag_scan"
    title = event.to_s == "found" ? "Получены данные по PetTag" : "PetTag отсканирован"
    detail = scan.location_label.presence || "QR-профиль открыт"

    create_or_find_by!(user:, source_key: "pet_tag_scan:#{scan.id}:#{kind}") do |notification|
      notification.kind = kind
      notification.title = title
      notification.body = "#{pet.name} • #{detail}"
      notification.target_path = Rails.application.routes.url_helpers.pet_pet_tag_path(pet)
      notification.occurred_at = scan.created_at || Time.current
      notification.metadata = { "pet_tag_scan_id" => scan.id, "pet_id" => pet.id }
    end
  end
end
