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

    "Канал пока недоступен. Проверьте настройки подключения."
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
      ["Email", "Основной канал для системных уведомлений и напоминаний."],
      ["Telegram", "Подключите чат, если удобнее получать напоминания в мессенджере."],
      ["VK", "Подключите диалог VK, чтобы получать напоминания там, где вы чаще отвечаете."],
      ["Push", "Включите уведомления в текущем браузере, если хотите получать быстрые сигналы на этом устройстве."]
    ]
  end
end
