class CreateAgentWebhooks < ActiveRecord::Migration[8.1]
  def change
    create_table :agent_webhooks do |t|
      t.string :agent_identifier, null: false
      t.string :url, null: false
      t.string :secret
      t.boolean :active, default: true, null: false
      t.json :event_types
      t.integer :failures, default: 0, null: false
      t.datetime :last_delivered_at
      t.datetime :last_failed_at

      t.timestamps
    end

    add_index :agent_webhooks, [:agent_identifier, :active],
              name: "idx_agent_webhooks_active_agent"
  end
end
