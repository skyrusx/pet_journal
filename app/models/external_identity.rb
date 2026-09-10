class ExternalIdentity < ApplicationRecord
  PROVIDERS = %w[vk yandex].freeze

  belongs_to :user

  validates :provider, presence: true, inclusion: { in: PROVIDERS }
  validates :uid, presence: true, length: { maximum: 255 }
  validates :provider, uniqueness: { scope: :user_id }
  validates :uid, uniqueness: { scope: :provider }
  validates :connected_at, presence: true

  scope :for_provider, ->(provider) { where(provider: provider.to_s) }

  def provider_name
    case provider
    when "vk" then "VK ID"
    when "yandex" then "Яндекс ID"
    else provider.to_s.humanize
    end
  end
end
