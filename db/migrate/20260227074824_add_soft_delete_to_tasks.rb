class AddSoftDeleteToTasks < ActiveRecord::Migration[8.1]
  def change
    add_column :tasks, :deleted_at, :datetime
    add_column :tasks, :deleted_by_id, :integer
    add_column :tasks, :deleted_by_agent, :string
    add_index :tasks, :deleted_at
  end
end
