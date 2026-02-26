# frozen_string_literal: true

class AddCommentTool < ApplicationTool
  description "Add a comment to a task"

  annotations(
    title: "Add Comment",
    read_only_hint: false,
    open_world_hint: false
  )

  arguments do
    required(:task_id).filled(:integer).description("Task ID")
    required(:body).filled(:string).description("Comment text (supports Markdown)")
    optional(:agent_identifier).filled(:string).description("Agent identifier (e.g., 'claude-code')")
  end

  def call(task_id:, body:, agent_identifier: nil)
    task = Task.find(task_id)
    comment = task.comments.create!(
      body: body,
      user: agent_identifier ? nil : current_user,
      agent_identifier: agent_identifier,
      comment_type: :comment
    )

    { id: comment.id, task_id: task.id, task_display_id: task.display_id, body: comment.body, author: comment.author_name }
  end
end
