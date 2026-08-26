class AddInterfaceTextSizeToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :interface_text_size, :string, default: "standard", null: false unless column_exists?(:users, :interface_text_size)
  end
end
