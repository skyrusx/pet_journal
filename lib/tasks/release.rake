namespace :release do
  desc "Check production runtime configuration"
  task check: :environment do
    report = PetJournal::ProductionReadiness.report

    if report[:missing_required_env].any?
      warn "Missing required production environment:"
      report[:missing_required_env].each { |key| warn "- #{key}" }
      exit 1
    end

    if report[:notification_warnings].any?
      warn "Notification configuration warnings:"
      report[:notification_warnings].each { |message| warn "- #{message}" }
    end

    puts "Production runtime configuration check passed."
  end
end
