# frozen_string_literal: true

class UpdateTaskTool < ApplicationTool
  description "Update task fields (title, description, priority, due date)"

  annotations(
    title: "Update Task",
    read_only_hint: false,
    open_world_hint: false
  )

  arguments do
    required(:task_id).filled(:integer).description("Task ID")
    optional(:title).filled(:string).description("New title")
    optional(:description).filled(:string).description("New description (Markdown)")
    optional(:priority).filled(:string).description("New priority: low, medium, high, critical")
    optional(:due_date).filled(:string).description("New due date (YYYY-MM-DD) or empty to clear")
    optional(:agent_identifier).filled(:string).description("Agent making the change")
  end

  def call(task_id:, **attrs)
    task = Task.find(task_id)
    update_attrs = attrs.compact.except(:agent_identifier)
    update_attrs[:agent_identifier] = attrs[:agent_identifier] if attrs[:agent_identifier]
    task.update!(update_attrs)

    { id: task.id, display_id: task.display_id, title: task.title, updated_fields: update_attrs.keys }
  end
end
