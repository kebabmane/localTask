class CreateProjectMembers < ActiveRecord::Migration[8.1]
  def change
    create_table :project_members do |t|
      t.references :project, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.integer :role, null: false, default: 0
      t.timestamps
    end

    add_index :project_members, [:project_id, :user_id], unique: true
  end
end
