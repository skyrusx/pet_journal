module NotificationChannelsHelper
  def notification_channel_type_options(include_web_push: true)
    keys = NotificationChannel.channel_types.keys
    keys -= ["web_push"] unless include_web_push

    keys.map { |key| [I18n.t("notification_channels.types.#{key}"), key] }
  end

  def notification_channel_hint(channel_type)
    {
      "email" => "Укажите адрес электронной почты, на который будут приходить уведомления.",
      "telegram" => "Telegram подключается через бота PetJournal — никаких chat_id вводить не нужно.",
      "vk" => "Можно вставить ссылку на профиль, короткое имя или числовой ID. Остальное PetJournal определит сам."
    }.fetch(channel_type.to_s, "Укажите данные канала.")
  end

  def notification_channel_address_label(channel_type)
    {
      "email" => "Email",
      "telegram" => "Telegram",
      "vk" => "Ваш профиль VK"
    }.fetch(channel_type.to_s, "Адрес")
  end

  def notification_channel_address_placeholder(channel_type)
    {
      "email" => "name@example.ru",
      "telegram" => "Подключается через бота",
      "vk" => "Например, vk.ru/username или @username"
    }.fetch(channel_type.to_s, "Укажите адрес канала")
  end

  def notification_channel_form_address(channel)
    return channel.address unless channel.channel_vk?

    screen_name = channel.settings["screen_name"].presence
    screen_name.present? ? "https://vk.ru/#{screen_name}" : channel.address
  end

  def notification_channel_display_address(channel)
    return "Уведомления в этом браузере" if channel.channel_web_push?

    if channel.channel_telegram?
      username = channel.settings["username"].presence
      display_name = channel.settings["display_name"].presence
      return [display_name, username.present? ? "@#{username}" : nil].compact.join(" · ").presence || "Telegram подключён"
    end

    if channel.channel_vk?
      screen_name = channel.settings["screen_name"].presence
      display_name = channel.settings["display_name"].presence
      return [display_name, screen_name.present? ? "@#{screen_name}" : nil].compact.join(" · ").presence || channel.address
    end

    channel.address.presence || "Адрес не указан"
  end

  def telegram_connection_url
    username = ENV["TELEGRAM_BOT_USERNAME"].to_s.delete_prefix("@").presence
    return if username.blank? || ENV["TELEGRAM_BOT_TOKEN"].blank? || current_user.blank?

    token = TelegramConnectionToken.generate(current_user)
    "https://t.me/#{username}?start=#{token}"
  end

  def telegram_bot_label
    username = ENV["TELEGRAM_BOT_USERNAME"].to_s.delete_prefix("@").presence
    username.present? ? "@#{username}" : "бот PetJournal"
  end

  def notification_channel_icon(channel_or_type, class_name: nil)
    type = channel_or_type.respond_to?(:channel_type) ? channel_or_type.channel_type : channel_or_type.to_s
    paths = {
      "email" => '<rect x="3.5" y="5.5" width="17" height="13" rx="2"/><path d="m5 7 7 5 7-5"/>',
      "telegram" => '<path d="M20.5 4.5 3.8 10.9c-1.1.4-1.1 1.1-.2 1.4l4.3 1.4 1.7 5.2c.2.7.1 1 .8 1 .5 0 .8-.2 1-.4l2.5-2.4 5.1 3.8c.9.5 1.6.2 1.8-.9L23 6c.3-1.4-.5-2-1.5-1.5Z"/><path d="m8 13.7 10.6-6.6-8.3 8.2-.3 3.3"/>',
      "vk" => '<path d="M4.2 7.1h3.1c.3 0 .5.2.6.5.7 2.2 1.7 4.1 3.1 5.7V7.7c0-.4.3-.7.7-.7h2.6c.4 0 .7.3.7.7v3.8c1.3-1.4 2.3-2.9 3.1-4.3.1-.2.3-.3.6-.3h3c.6 0 .9.7.6 1.2-1 1.7-2.2 3.3-3.6 4.8 1.5 1.3 2.8 2.8 4 4.6.4.6 0 1.3-.7 1.3h-3.1c-.3 0-.5-.1-.7-.4-.9-1.3-1.9-2.4-3.2-3.4v3.1c0 .4-.3.7-.7.7h-1.8c-4.4 0-7.3-3.1-9.2-10.8-.1-.5.3-.9.9-.9Z"/>',
      "web_push" => '<path d="M18 10.5a6 6 0 0 0-12 0c0 5-2 5.5-2 7h16c0-1.5-2-2-2-7z"/><path d="M10 20a2.2 2.2 0 0 0 4 0"/>'
    }

    content_tag(
      :svg,
      paths.fetch(type, paths.fetch("web_push")).html_safe,
      viewBox: "0 0 24 24",
      fill: "none",
      xmlns: "http://www.w3.org/2000/svg",
      aria: { hidden: true },
      class: class_names("pj-notification-channel-icon", class_name)
    )
  end

  def notification_delivery_status_label(delivery)
    return "Ожидает повтора" if delivery.status_pending? && delivery.attempts_count.positive?

    I18n.t("notification_channels.delivery_statuses.#{delivery.status}")
  end

  def notification_delivery_status_class(delivery)
    return "status-pill success" if delivery.status_sent?
    return "lost-pill" if delivery.status_failed?
    return "status-pill muted" if delivery.status_skipped?

    "status-pill"
  end

  def notification_channel_status_class(channel)
    return "status-pill muted" unless channel.enabled?
    return "lost-pill" unless channel.ready_for_delivery?
    return "status-pill success" if channel.verified?

    "status-pill"
  end

  def notification_channel_status_label(channel)
    return "Выключен" unless channel.enabled?
    return "Нужна настройка" unless channel.ready_for_delivery?
    return "Готов" if channel.verified?

    "Нужна проверка"
  end

  def notification_channel_configuration_label(channel)
    return "Канал готов к отправке." if channel.ready_for_delivery?

    channel.configuration_issues.to_sentence.presence || "Проверьте настройки подключения."
  end

  def notification_delivery_filter_options(counts)
    [
      ["Все", "all", counts[:all]],
      ["В очереди", "pending", counts[:pending]],
      ["Отправлено", "sent", counts[:sent]],
      ["Ошибки", "failed", counts[:failed]],
      ["Пропущено", "skipped", counts[:skipped]]
    ]
  end

  def notification_channel_onboarding_steps
    [
      ["Email", "Укажите почту — PetJournal будет отправлять туда напоминания."],
      ["Telegram", "Нажмите «Подключить Telegram» и Start в боте. Никаких ID искать не нужно."],
      ["VK", "Вставьте ссылку на свой профиль VK или короткое имя — PetJournal определит ID сам."],
      ["Push", "Включите уведомления в браузере, чтобы получать быстрые сигналы на этом устройстве."]
    ]
  end
end
