# frozen_string_literal: true

class SearchTasksTool < ApplicationTool
  description "Search for tasks by title or description across all projects"

  annotations(
    title: "Search Tasks",
    read_only_hint: true,
    open_world_hint: false
  )

  arguments do
    required(:query).filled(:string).description("Search query to match against task titles and descriptions")
    optional(:project).filled(:string).description("Limit search to a specific project (ID or prefix)")
  end

  def call(query:, project: nil)
    tasks = Task.includes(:task_status, :project, :assignee)
    tasks = tasks.where(project: find_project(project)) if project

    tasks = tasks.where("title LIKE ? OR description LIKE ?", "%#{query}%", "%#{query}%")

    tasks.limit(25).map do |t|
      {
        id: t.id,
        display_id: t.display_id,
        project: t.project.name,
        title: t.title,
        status: t.task_status.name,
        priority: t.priority,
        assignee: t.assignee&.name
      }
    end
  end
end
