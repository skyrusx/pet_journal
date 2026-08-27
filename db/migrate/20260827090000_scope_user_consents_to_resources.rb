class ScopeUserConsentsToResources < ActiveRecord::Migration[7.2]
  def change
    add_column :user_consents, :consentable_type, :string, limit: 64
    add_column :user_consents, :consentable_id, :bigint

    remove_index :user_consents, name: "index_active_user_consents_on_user_type_version"

    add_index :user_consents,
              %i[user_id consent_type document_version],
              unique: true,
              where: "revoked_at IS NULL AND consentable_type IS NULL AND consentable_id IS NULL",
              name: "index_active_global_user_consents"

    add_index :user_consents,
              %i[user_id consent_type consentable_type consentable_id],
              unique: true,
              where: "revoked_at IS NULL AND consentable_type IS NOT NULL AND consentable_id IS NOT NULL",
              name: "index_active_scoped_user_consents"

    add_index :user_consents,
              %i[consentable_type consentable_id],
              name: "index_user_consents_on_consentable"
  end
end
