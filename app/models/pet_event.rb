class PetEvent < ApplicationRecord
  belongs_to :pet
  has_many :reminder_completions, dependent: :nullify
  has_many :pet_documents, dependent: :nullify
  has_many_attached :files

  enum :event_type, { note: 0, vaccination: 1, treatment: 2, visit: 3, illness: 4, weight: 5, document: 6 }
  enum :severity, { mild: 0, moderate: 1, severe: 2, critical: 3 }, prefix: true

  validates :event_type, :event_date, presence: true
  validates :weight_value, numericality: { greater_than: 0, less_than: 500 }, allow_blank: true
  validates :severity, presence: true, if: :illness?
  validate :valid_until_after_event_date
  validate :course_end_after_start
  validate :symptom_end_after_start

  EVENT_TYPE_LABELS = {
    "note" => "Заметка",
    "vaccination" => "Вакцинация",
    "treatment" => "Лекарство / обработка",
    "visit" => "Визит к врачу",
    "illness" => "Симптом / болезнь",
    "weight" => "Вес",
    "document" => "Документ"
  }.freeze

  def event_type_label
    EVENT_TYPE_LABELS[event_type] || event_type
  end

  def structured?
    structured_rows.any?
  end

  def structured_rows
    case event_type
    when "weight" then weight_rows
    when "vaccination" then vaccination_rows
    when "treatment" then treatment_rows
    when "visit" then visit_rows
    when "illness" then illness_rows
    when "document" then document_rows
    else []
    end
  end

  def summary
    first_value = structured_rows.first&.last
    return first_value if first_value.present?

    description.presence
  end

  private

  def weight_rows
    rows = []
    rows << ["Вес", "#{weight_value} #{weight_unit}"] if weight_value.present?
    rows
  end

  def vaccination_rows
    [
      ["Вакцина", vaccine_name],
      ["Партия", vaccine_batch],
      ["Клиника", clinic_name],
      ["Врач", veterinarian_name],
      ["Действует до", valid_until&.strftime("%d.%m.%Y")]
    ].select { |_label, value| value.present? }
  end

  def treatment_rows
    [
      ["Препарат", medication_name],
      ["Дозировка", dosage],
      ["Начало курса", course_started_on&.strftime("%d.%m.%Y")],
      ["Окончание курса", course_ended_on&.strftime("%d.%m.%Y")],
      ["Следующее действие", next_action_at&.strftime("%d.%m.%Y %H:%M")]
    ].select { |_label, value| value.present? }
  end

  def visit_rows
    [
      ["Клиника", clinic_name],
      ["Врач", veterinarian_name],
      ["Диагноз", diagnosis],
      ["Рекомендации", recommendations],
      ["Следующее действие", next_action_at&.strftime("%d.%m.%Y %H:%M")]
    ].select { |_label, value| value.present? }
  end

  def illness_rows
    [
      ["Симптомы", symptoms],
      ["Тяжесть", I18n.t("pet_events.severities.#{severity}")],
      ["Начало", symptom_started_on&.strftime("%d.%m.%Y")],
      ["Окончание", symptom_ended_on&.strftime("%d.%m.%Y")],
      ["Диагноз", diagnosis],
      ["Рекомендации", recommendations]
    ].select { |_label, value| value.present? }
  end

  def document_rows
    pet_documents.map { |document| ["Документ", document.title] }
  end

  def valid_until_after_event_date
    return if valid_until.blank? || event_date.blank? || valid_until >= event_date

    errors.add(:valid_until, "не может быть раньше даты события")
  end

  def course_end_after_start
    return if course_started_on.blank? || course_ended_on.blank? || course_ended_on >= course_started_on

    errors.add(:course_ended_on, "не может быть раньше начала курса")
  end

  def symptom_end_after_start
    return if symptom_started_on.blank? || symptom_ended_on.blank? || symptom_ended_on >= symptom_started_on

    errors.add(:symptom_ended_on, "не может быть раньше начала симптомов")
  end
end
