# frozen_string_literal: true

# Keep password recovery responses identical whether an email exists or not.
# This prevents account enumeration through the public recovery form.
Devise.setup do |config|
  config.paranoid = true
end
