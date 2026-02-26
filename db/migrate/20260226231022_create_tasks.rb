class CreateTasks < ActiveRecord::Migration[8.1]
  def change
    create_table :tasks do |t|
      t.string :title, null: false
      t.text :description
      t.integer :priority, default: 1, null: false
      t.integer :position, null: false, default: 0
      t.integer :task_number, null: false
      t.date :due_date
      t.references :project, null: false, foreign_key: true
      t.references :task_status, null: false, foreign_key: true
      t.references :creator, null: false, foreign_key: { to_table: :users }
      t.references :assignee, null: true, foreign_key: { to_table: :users }
      t.string :agent_identifier
      t.string :agent_session_id
      t.datetime :completed_at

      t.timestamps
    end

    add_index :tasks, [:project_id, :task_number], unique: true
    add_index :tasks, [:task_status_id, :position]
    add_index :tasks, :priority
    add_index :tasks, :due_date
    add_index :tasks, :agent_identifier
  end
end
