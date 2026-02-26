# frozen_string_literal: true

class ProjectBoardResource < ApplicationResource
  uri "localtask://projects/{project_id}/board"
  resource_name "Project Board"
  mime_type "application/json"
  description "Current state of a project's Kanban board with all columns and tasks"

  def content(uri:)
    project_id = uri.match(/projects\/(\d+)/)[1]
    project = Project.includes(task_statuses: { tasks: [:assignee, :creator] }).find(project_id)

    board = project.task_statuses.ordered.map do |status|
      {
        status: { id: status.id, name: status.name, color: status.color },
        tasks: status.tasks.sort_by(&:position).map do |t|
          {
            id: t.id,
            display_id: t.display_id,
            title: t.title,
            priority: t.priority,
            assignee: t.assignee&.name,
            agent: t.agent_identifier
          }
        end
      }
    end

    JSON.generate({ project: project.name, prefix: project.prefix, columns: board })
  end
end
