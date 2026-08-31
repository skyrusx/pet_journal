class HardenPublicPersonalDataFlows < ActiveRecord::Migration[7.2]
  def up
    add_column :pet_tag_scans, :finder_consent_version, :string, limit: 32
    add_column :pet_tag_scans, :finder_privacy_policy_version, :string, limit: 32
    add_column :pet_tag_scans, :finder_consented_at, :datetime

    # Legacy contact switches were simple publication toggles and did not record
    # the separate dissemination consent required for human personal data.
    # Fail closed until that dedicated flow exists.
    execute "UPDATE pet_tags SET show_phone = FALSE WHERE show_phone = TRUE"
    execute "UPDATE pet_profile_shares SET show_owner_contact = FALSE WHERE show_owner_contact = TRUE"
  end

  def down
    remove_column :pet_tag_scans, :finder_consented_at
    remove_column :pet_tag_scans, :finder_privacy_policy_version
    remove_column :pet_tag_scans, :finder_consent_version

    # Public contact flags intentionally remain disabled on rollback. Re-enabling
    # them without a valid dissemination-consent record would recreate the risk
    # this migration removes.
  end
end
