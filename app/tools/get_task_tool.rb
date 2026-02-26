# frozen_string_literal: true

class GetTaskTool < ApplicationTool
  description "Get detailed information about a specific task including comments and dependencies"

  annotations(
    title: "Get Task Detail",
    read_only_hint: true,
    open_world_hint: false
  )

  arguments do
    required(:task_id).filled(:integer).description("Task ID")
  end

  def call(task_id:)
    task = Task.includes(:task_status, :assignee, :creator, :comments, :dependencies).find(task_id)
    {
      id: task.id,
      display_id: task.display_id,
      title: task.title,
      description: task.description,
      status: task.task_status.name,
      priority: task.priority,
      assignee: task.assignee&.name,
      creator: task.creator.name,
      agent: task.agent_identifier,
      due_date: task.due_date&.iso8601,
      completed_at: task.completed_at&.iso8601,
      blocked: task.blocked?,
      dependencies: task.dependencies.map { |d| { id: d.id, display_id: d.display_id, title: d.title, status: d.task_status.name } },
      dependents: task.dependents.map { |d| { id: d.id, display_id: d.display_id, title: d.title } },
      comments: task.comments.order(:created_at).map { |c|
        { id: c.id, body: c.body, author: c.author_name, type: c.comment_type, created_at: c.created_at.iso8601 }
      },
      created_at: task.created_at.iso8601,
      updated_at: task.updated_at.iso8601
    }
  end
end
