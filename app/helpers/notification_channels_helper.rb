module NotificationChannelsHelper
  def notification_channel_type_options(include_web_push: true)
    keys = NotificationChannel.channel_types.keys
    keys -= ["web_push"] unless include_web_push

    keys.map { |key| [I18n.t("notification_channels.types.#{key}"), key] }
  end

  def notification_channel_hint(channel_type)
    I18n.t("notification_channels.hints.#{channel_type}", default: "Укажите данные канала.")
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

    channel.configuration_issues.to_sentence
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
      ["Email", "Проверьте SMTP в окружении Rails. Канал email аккаунта создается автоматически, если других каналов нет."],
      ["Telegram", "Создайте бота, задайте TELEGRAM_BOT_TOKEN и укажите chat_id пользователя или группы."],
      ["VK", "Задайте VK_GROUP_TOKEN от сообщества и укажите peer_id нужного диалога."],
      ["Push", "Задайте VAPID_PUBLIC_KEY и VAPID_PRIVATE_KEY, затем включите push в нужном браузере."]
    ]
  end
end
