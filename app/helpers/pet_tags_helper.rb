module PetTagsHelper
  NOTIFICATION_LABELS = {
    "lost_mode" => "Только в Lost Mode",
    "always" => "При каждом сканировании",
    "never" => "Не уведомлять"
  }.freeze

  def notification_options
    NOTIFICATION_LABELS.map { |value, label| [label, value] }
  end

  def notification_label(value)
    NOTIFICATION_LABELS.fetch(value, value)
  end

  def scan_time_label(scan)
    scan.created_at.strftime("%d.%m.%Y %H:%M")
  end
end
