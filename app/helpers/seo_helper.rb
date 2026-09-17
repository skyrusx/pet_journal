module SeoHelper
  DEFAULT_TITLE = "PetJournal — онлайн-дневник питомца".freeze
  DEFAULT_DESCRIPTION = "PetJournal — онлайн-сервис для владельцев питомцев. Он помогает сохранять историю здоровья и событий, помнить о важных делах и быстро находить нужную информацию.".freeze
  DEFAULT_OG_TITLE = "PetJournal — дневник вашего питомца".freeze
  DEFAULT_OG_DESCRIPTION = "Сохраняйте историю питомца и важные события, чтобы нужная информация не терялась и была доступна в нужный момент.".freeze
  DEFAULT_IMAGE = "petjournal/hero-composite.png".freeze

  def set_seo_meta(title: nil, description: nil, image: nil, url: nil, og_title: nil, og_description: nil)
    content_for(:seo_title, title) if title.present?
    content_for(:seo_description, description) if description.present?
    content_for(:seo_image, image) if image.present?
    content_for(:seo_url, url) if url.present?
    content_for(:og_title, og_title) if og_title.present?
    content_for(:og_description, og_description) if og_description.present?
  end

  def seo_title
    content_for(:seo_title).presence || DEFAULT_TITLE
  end

  def seo_description
    content_for(:seo_description).presence || DEFAULT_DESCRIPTION
  end

  def og_title
    content_for(:og_title).presence || DEFAULT_OG_TITLE
  end

  def og_description
    content_for(:og_description).presence || DEFAULT_OG_DESCRIPTION
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
