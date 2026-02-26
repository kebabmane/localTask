# frozen_string_literal: true

class CreateTaskTool < ApplicationTool
  description "Create a new task in a project"

  annotations(
    title: "Create Task",
    read_only_hint: false,
    open_world_hint: false
  )

  arguments do
    required(:project).filled(:string).description("Project ID or prefix (e.g., 'LT')")
    required(:title).filled(:string).description("Task title")
    optional(:description).filled(:string).description("Task description (supports Markdown)")
    optional(:priority).filled(:string).description("Priority: low, medium, high, critical. Default: medium")
    optional(:status).filled(:string).description("Status name. Default: project's default status")
    optional(:due_date).filled(:string).description("Due date in YYYY-MM-DD format")
    optional(:agent_identifier).filled(:string).description("Agent identifier (e.g., 'claude-code')")
  end

  def call(project:, title:, description: nil, priority: "medium", status: nil, due_date: nil, agent_identifier: nil)
    proj = find_project(project)
    task_status = if status
      proj.task_statuses.find_by!(name: status)
    else
      proj.task_statuses.default_status.first
    end

    task = proj.tasks.create!(
      title: title,
      description: description,
      priority: priority,
      task_status: task_status,
      due_date: due_date,
      creator: current_user,
      agent_identifier: agent_identifier
    )

    { id: task.id, display_id: task.display_id, title: task.title, status: task.task_status.name }
  end
end
