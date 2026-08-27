class CreateUserConsents < ActiveRecord::Migration[7.2]
  def change
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

      t.timestamps
    end

    add_index :user_consents,
              %i[user_id consent_type document_version],
              unique: true,
              where: "revoked_at IS NULL",
              name: "index_active_user_consents_on_user_type_version"
    add_index :user_consents,
              %i[user_id consent_type accepted_at],
              name: "index_user_consents_on_user_type_accepted_at"
  end
end
