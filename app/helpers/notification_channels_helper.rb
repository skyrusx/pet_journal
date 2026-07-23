module NotificationChannelsHelper
  def notification_channel_type_options
    NotificationChannel.channel_types.keys.map { |key| [I18n.t("notification_channels.types.#{key}"), key] }
  end

  def notification_channel_hint(channel_type)
    I18n.t("notification_channels.hints.#{channel_type}", default: "Укажите данные канала.")
  end

  def notification_delivery_status_label(delivery)
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
    return "status-pill success" if channel.verified?

    "status-pill"
  end

  def notification_channel_status_label(channel)
    return "Выключен" unless channel.enabled?
    return "Готов" if channel.verified?

    "Нужна проверка"
  end
end
