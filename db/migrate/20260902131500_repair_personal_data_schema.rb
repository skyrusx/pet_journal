class RepairPersonalDataSchema < ActiveRecord::Migration[7.2]
  def up
    ensure_user_consents_table
    ensure_pet_tag_scan_consent_columns
  end

  def down
    raise ActiveRecord::IrreversibleMigration, "This migration repairs schema state and must not remove existing personal-data records"
  end

  private

  def ensure_user_consents_table
    unless table_exists?(:user_consents)
      create_table :user_consents do |t|
        t.references :user, null: false, foreign_key: true
        t.string :consent_type, null: false, limit: 64
        t.string :document_version, null: false, limit: 32
        t.datetime :accepted_at, null: false
        t.datetime :revoked_at
        t.inet :ip_address
        t.string :user_agent, limit: 500
        t.string :source, null: false, limit: 64
        t.jsonb :metadata, null: false, default: {}
        t.string :consentable_type, limit: 64
        t.bigint :consentable_id

        t.timestamps
      end
    end

    add_index :user_consents, :user_id unless index_exists?(:user_consents, :user_id)

    unless index_named?(:user_consents, "index_active_global_user_consents")
      add_index :user_consents,
                %i[user_id consent_type document_version],
                unique: true,
                where: "revoked_at IS NULL AND consentable_type IS NULL AND consentable_id IS NULL",
                name: "index_active_global_user_consents"
    end

    unless index_named?(:user_consents, "index_active_scoped_user_consents")
      add_index :user_consents,
                %i[user_id consent_type consentable_type consentable_id],
                unique: true,
                where: "revoked_at IS NULL AND consentable_type IS NOT NULL AND consentable_id IS NOT NULL",
                name: "index_active_scoped_user_consents"
    end

    unless index_named?(:user_consents, "index_user_consents_on_user_type_accepted_at")
      add_index :user_consents,
                %i[user_id consent_type accepted_at],
                name: "index_user_consents_on_user_type_accepted_at"
    end

    unless index_named?(:user_consents, "index_user_consents_on_consentable")
      add_index :user_consents,
                %i[consentable_type consentable_id],
                name: "index_user_consents_on_consentable"
    end

    add_foreign_key :user_consents, :users unless foreign_key_exists?(:user_consents, :users)
  end

  def ensure_pet_tag_scan_consent_columns
    add_column :pet_tag_scans, :finder_consent_version, :string, limit: 32 unless column_exists?(:pet_tag_scans, :finder_consent_version)
    add_column :pet_tag_scans, :finder_privacy_policy_version, :string, limit: 32 unless column_exists?(:pet_tag_scans, :finder_privacy_policy_version)
    add_column :pet_tag_scans, :finder_consented_at, :datetime unless column_exists?(:pet_tag_scans, :finder_consented_at)
  end

  def index_named?(table_name, index_name)
    connection.indexes(table_name).any? { |index| index.name == index_name }
  end
end
