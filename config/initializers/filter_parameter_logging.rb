# Be sure to restart your server when you modify this file.

# Configure parameters to be partially matched (e.g. passw matches password) and filtered from the log file.
# Use this to limit dissemination of sensitive information.
# See the ActiveSupport::ParameterFilter documentation for supported notations and behaviors.
Rails.application.config.filter_parameters += [
  :passw,
  :email,
  :phone,
  :secret,
  :token,
  :_key,
  :crypt,
  :salt,
  :certificate,
  :otp,
  :ssn,
  :auth,
  :p256dh,
  :endpoint,
  :subject_full_name,
  :finder_name,
  :finder_contact,
  :finder_message,
  :location_note,
  :latitude,
  :longitude,
  :diagnosis,
  :symptoms,
  :recommendations,
  :medical_notes,
  :behavior_notes,
  :last_seen_location,
  :public_message,
  :lost_message,
  :found_message,
  :notes,
  :description,
  :dosage,
  :veterinarian_name,
  :chip_number,
  :passport_number
]
