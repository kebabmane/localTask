class ProjectDetailSerializer
  def initialize(project)
    @project = project
  end

  def as_json(*)
    {
      id: @project.id,
      name: @project.name,
      prefix: @project.prefix,
      description: @project.description,
      color: @project.color,
      icon: @project.icon,
      archived: @project.archived,
      statuses: @project.task_statuses.ordered.map { |s|
        { id: s.id, name: s.name, color: s.color, position: s.position,
          is_default: s.is_default, is_closed: s.is_closed,
          task_count: @project.tasks.where(task_status_id: s.id).size }
      },
      created_at: @project.created_at.iso8601,
      updated_at: @project.updated_at.iso8601
    }
  end
end
