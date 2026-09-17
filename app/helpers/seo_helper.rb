module SeoHelper
  DEFAULT_TITLE = "PetJournal — всё важное о питомце рядом".freeze
  DEFAULT_DESCRIPTION = "PetJournal — сервис для владельцев питомцев: журнал событий, здоровье, документы, напоминания и PetTag в одном месте.".freeze
  DEFAULT_IMAGE = "petjournal/hero-composite.png".freeze

  def set_seo_meta(title: nil, description: nil, image: nil, url: nil)
    content_for(:seo_title, title) if title.present?
    content_for(:seo_description, description) if description.present?
    content_for(:seo_image, image) if image.present?
    content_for(:seo_url, url) if url.present?
  end

  def seo_title
    content_for(:seo_title).presence || DEFAULT_TITLE
  end

  def seo_description
    content_for(:seo_description).presence || DEFAULT_DESCRIPTION
  end

  def seo_url
    content_for(:seo_url).presence || canonical_url
  end

  def seo_image_url
    image = content_for(:seo_image).presence || DEFAULT_IMAGE
    return image if image.match?(%r{\Ahttps?://})

    "#{canonical_origin}#{asset_path(image)}"
  end
end
