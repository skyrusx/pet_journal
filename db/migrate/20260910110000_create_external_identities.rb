class CreateExternalIdentities < ActiveRecord::Migration[7.2]
  def change
    create_table :external_identities do |t|
      t.references :user, null: false, foreign_key: true
      t.string :provider, null: false
      t.string :uid, null: false
      t.datetime :connected_at, null: false
      t.datetime :last_used_at

      t.timestamps
    end

    add_index :external_identities, %i[provider uid], unique: true
    add_index :external_identities, %i[user_id provider], unique: true

    add_column :users, :password_configured, :boolean, default: true, null: false
  end
end
