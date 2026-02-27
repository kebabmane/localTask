class CreateMentions < ActiveRecord::Migration[8.1]
  def change
    create_table :mentions do |t|
      t.references :comment, null: false, foreign_key: true
      t.string :mention_type, null: false
      t.string :mention_text, null: false
      t.string :agent_identifier
      t.references :mentioned_task, null: true, foreign_key: { to_table: :tasks }

      t.timestamps
    end

    add_index :mentions, :agent_identifier
  end
end
