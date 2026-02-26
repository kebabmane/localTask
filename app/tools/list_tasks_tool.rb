# frozen_string_literal: true

class ListTasksTool < ApplicationTool
  description "List tasks in a project, optionally filtered by status, priority, or agent"

  annotations(
    title: "List Tasks",
    read_only_hint: true,
    open_world_hint: false
  )

  arguments do
    required(:project).filled(:string).description("Project ID or prefix (e.g., 'LT')")
    optional(:status).filled(:string).description("Filter by status name (e.g., 'In Progress', 'With Agent')")
    optional(:priority).filled(:string).description("Filter by priority: low, medium, high, critical")
    optional(:agent).filled(:string).description("Filter by agent identifier (e.g., 'claude-code')")
  end

  def call(project:, status: nil, priority: nil, agent: nil)
    proj = find_project(project)
    tasks = proj.tasks.includes(:task_status, :assignee, :creator).ordered

    tasks = tasks.joins(:task_status).where(task_statuses: { name: status }) if status
    tasks = tasks.where(priority: priority) if priority
    tasks = tasks.by_agent(agent) if agent

    tasks.map do |t|
      {
        id: t.id,
        display_id: t.display_id,
        title: t.title,
        status: t.task_status.name,
        priority: t.priority,
        assignee: t.assignee&.name,
        agent: t.agent_identifier,
        due_date: t.due_date&.iso8601,
        blocked: t.blocked?,
        comments_count: t.comments.count
      }
    end
  end
end
