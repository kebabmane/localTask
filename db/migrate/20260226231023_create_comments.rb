class CreateComments < ActiveRecord::Migration[8.1]
  def change
    create_table :comments do |t|
      t.text :body, null: false
      t.references :task, null: false, foreign_key: true
      t.references :user, null: true, foreign_key: true
      t.string :agent_identifier
      t.string :agent_session_id
      t.integer :comment_type, default: 0, null: false

      t.timestamps
    end

    add_index :comments, [:task_id, :created_at]
  end
end
