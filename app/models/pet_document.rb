class PetDocument < ApplicationRecord
  belongs_to :pet
  belongs_to :pet_event, optional: true
  belongs_to :reminder, optional: true

  has_many_attached :files

  enum :document_type, {
    other: 0,
    passport: 1,
    vaccination: 2,
    lab_result: 3,
    prescription: 4,
    certificate: 5,
    receipt: 6,
    insurance: 7
  }, prefix: true

  validates :title, :document_type, presence: true
  validates :expiry_reminder_days, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 365 }
  validate :expires_after_issue

  scope :recent, -> { order(created_at: :desc) }
  scope :expires_soon, -> { where(expires_on: Date.current..30.days.from_now.to_date).order(:expires_on) }
  scope :expired, -> { where(expires_on: ...Date.current).order(expires_on: :desc) }

  def document_type_label
    I18n.t("pet_documents.types.#{document_type}")
  end

  def expired?
    expires_on.present? && expires_on < Date.current
  end

  def expires_soon?
    expires_on.present? && expires_on.between?(Date.current, 30.days.from_now.to_date)
  end

  def status_label
    return "Просрочен" if expired?
    return "Скоро истекает" if expires_soon?
    return "Без срока" if expires_on.blank?

    "Актуален"
  end

  def status_tone
    return "danger" if expired?
    return "warning" if expires_soon?
    return "muted" if expires_on.blank?

    "success"
  end

  def sync_journal_event!
    event = pet_event || pet.pet_events.build(event_type: :document, event_date: issued_on || Date.current)
    event.assign_attributes(
      event_type: :document,
      title: title,
      event_date: issued_on || event.event_date || Date.current,
      description: journal_description
    )
    event.save!
    update_column(:pet_event_id, event.id) if pet_event_id != event.id
    event
  end

  def sync_expiry_reminder!
    if expires_on.blank?
      old_reminder = reminder
      update_column(:reminder_id, nil) if reminder_id.present?
      old_reminder&.destroy!
      return
    end

    reminder_date = expires_on - expiry_reminder_days.days
    remind_at = Time.zone.local(reminder_date.year, reminder_date.month, reminder_date.day, 9, 0, 0)
    target = reminder || pet.reminders.build(reminder_type: :other, repeat_rule: :once)
    target.assign_attributes(
      title: "Проверить документ: #{title}",
      reminder_type: reminder_type_for_document,
      remind_at:,
      next_run_at: remind_at,
      repeat_rule: :once,
      status: :active,
      note: "Срок действия документа: #{expires_on.strftime("%d.%m.%Y")}"
    )
    target.save!
    update_column(:reminder_id, target.id) if reminder_id != target.id
    target
  end

  private

  def expires_after_issue
    return if issued_on.blank? || expires_on.blank? || expires_on >= issued_on

    errors.add(:expires_on, "не может быть раньше даты выдачи")
  end

  def journal_description
    [
      "Документ: #{document_type_label}",
      issuer.present? ? "Кем выдан: #{issuer}" : nil,
      number.present? ? "Номер: #{number}" : nil,
      expires_on.present? ? "Срок действия: #{expires_on.strftime("%d.%m.%Y")}" : nil,
      notes.presence
    ].compact.join("\n")
  end

  def reminder_type_for_document
    return :vaccination if document_type_vaccination?
    return :visit if document_type_certificate? || document_type_lab_result?

    :other
  end
end
