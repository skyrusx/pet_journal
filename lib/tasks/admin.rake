namespace :admin do
  desc "Grant the admin role to a user by email"
  task :grant, [:email] => :environment do |_task, args|
    email = args[:email].to_s.strip.downcase
    abort "Usage: bin/rails 'admin:grant[user@example.com]'" if email.blank?

    user = User.find_by("LOWER(email) = ?", email)
    abort "User not found: #{email}" unless user

    if user.admin?
      puts "#{user.email} is already an admin"
      next
    end

    user.update!(role: :admin)
    puts "Admin role granted to #{user.email}"
  end
end
