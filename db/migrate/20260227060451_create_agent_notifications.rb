class CreateAgentNotifications < ActiveRecord::Migration[8.1]
  def change
    create_table :agent_notifications do |t|
      t.string :agent_identifier, null: false
      t.string :event_type, null: false
      t.references :task, null: false, foreign_key: true
      t.references :comment, null: true, foreign_key: true
      t.text :message, null: false
      t.json :payload
      t.boolean :read, default: false, null: false
      t.datetime :read_at

      t.timestamps
    end

    add_index :agent_notifications, [:agent_identifier, :read, :created_at],
              name: "idx_agent_notifications_unread"
  end
end
