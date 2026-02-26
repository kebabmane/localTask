class CreateProjects < ActiveRecord::Migration[8.1]
  def change
    create_table :projects do |t|
      t.string :name, null: false
      t.text :description
      t.string :color, default: "#6366f1", null: false
      t.string :icon, default: "folder"
      t.string :prefix, null: false
      t.integer :position, null: false, default: 0
      t.boolean :archived, default: false, null: false
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end

    add_index :projects, :position
    add_index :projects, :prefix, unique: true
  end
end
