class ProjectSerializer
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
      task_count: @project.tasks.size,
      created_at: @project.created_at.iso8601,
      updated_at: @project.updated_at.iso8601
    }
  end
end
