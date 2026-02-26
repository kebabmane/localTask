class AddFieldsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :name, :string, null: false, default: ""
    add_column :users, :role, :integer, default: 0, null: false
    add_column :users, :avatar_color, :string, default: "#6366f1"
  end
end
