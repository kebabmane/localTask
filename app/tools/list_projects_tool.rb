# frozen_string_literal: true

class ListProjectsTool < ApplicationTool
  description "List all projects with their statuses and task counts"

  annotations(
    title: "List Projects",
    read_only_hint: true,
    open_world_hint: false
  )

  arguments do
    optional(:include_archived).filled(:bool).description("Include archived projects (default: false)")
  end

  def call(include_archived: false)
    projects = Project.includes(:task_statuses)
    projects = projects.active unless include_archived

    projects.map do |p|
      {
        id: p.id,
        name: p.name,
        prefix: p.prefix,
        description: p.description,
        task_count: p.tasks.count,
        open_task_count: p.tasks.open.count,
        statuses: p.task_statuses.ordered.map { |s| { id: s.id, name: s.name, color: s.color } }
      }
    end
  end
end
