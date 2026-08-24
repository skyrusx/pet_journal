class CreateInAppNotifications < ActiveRecord::Migration[7.2]
  def change
    create_table :in_app_notifications do |t|
      t.references :user, null: false, foreign_key: true
      t.string :kind, null: false
      t.string :title, null: false
      t.text :body
      t.string :target_path
      t.string :source_key, null: false
      t.datetime :occurred_at, null: false
      t.datetime :read_at
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :in_app_notifications, %i[user_id source_key], unique: true
    add_index :in_app_notifications, %i[user_id read_at]
    add_index :in_app_notifications, %i[user_id occurred_at]
  end
end
