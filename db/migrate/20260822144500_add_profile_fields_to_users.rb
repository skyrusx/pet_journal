class AddProfileFieldsToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :name, :string unless column_exists?(:users, :name)
    add_column :users, :phone, :string unless column_exists?(:users, :phone)
  end
end
