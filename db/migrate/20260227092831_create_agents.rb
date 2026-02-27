class CreateAgents < ActiveRecord::Migration[8.1]
  def change
    create_table :agents do |t|
      t.references :user, null: false, foreign_key: true
      t.references :api_token, foreign_key: true
      t.string :name, null: false
      t.string :identifier, null: false
      t.text :description

      t.timestamps
    end

    add_index :agents, :identifier, unique: true
  end
end
