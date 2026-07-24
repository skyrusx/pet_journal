class PetEvent < ApplicationRecord
  belongs_to :pet
  has_many :reminder_completions, dependent: :nullify
  has_many :pet_documents, dependent: :nullify
  has_many_attached :files

  enum :event_type, { note: 0, vaccination: 1, treatment: 2, visit: 3, illness: 4, weight: 5, document: 6 }

  validates :event_type, :event_date, presence: true

  EVENT_TYPE_LABELS = {
    "note" => "Заметка",
    "vaccination" => "Прививка",
    "treatment" => "Обработка",
    "visit" => "Прием у врача",
    "illness" => "Болезнь / симптом",
    "weight" => "Вес",
    "document" => "Документ"
  }.freeze

  def event_type_label
    EVENT_TYPE_LABELS[event_type] || event_type
  end
end
