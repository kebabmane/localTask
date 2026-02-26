# frozen_string_literal: true

class UpdateTaskStatusTool < ApplicationTool
  description "Move a task to a different status (e.g., 'In Progress' to 'With Agent')"

  annotations(
    title: "Update Task Status",
    read_only_hint: false,
    open_world_hint: false
  )

  arguments do
    required(:task_id).filled(:integer).description("Task ID")
    required(:status).filled(:string).description("New status name (e.g., 'With Agent', 'Done', 'In Progress')")
    optional(:agent_identifier).filled(:string).description("Agent making the change")
  end

  def call(task_id:, status:, agent_identifier: nil)
    task = Task.find(task_id)
    old_status_name = task.task_status.name
    new_status = task.project.task_statuses.find_by!(name: status)

    task.update!(
      task_status: new_status,
      agent_identifier: agent_identifier || task.agent_identifier
    )

    { id: task.id, display_id: task.display_id, title: task.title, old_status: old_status_name, new_status: new_status.name }
  end
end
