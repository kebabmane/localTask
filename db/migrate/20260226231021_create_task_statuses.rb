class CreateTaskStatuses < ActiveRecord::Migration[8.1]
  def change
    create_table :task_statuses do |t|
      t.string :name, null: false
      t.string :color, null: false, default: "#94a3b8"
      t.integer :position, null: false
      t.references :project, null: false, foreign_key: true
      t.boolean :is_default, default: false, null: false
      t.boolean :is_closed, default: false, null: false

      t.timestamps
    end

    add_index :task_statuses, [:project_id, :position]
    add_index :task_statuses, [:project_id, :name], unique: true
  end
end
