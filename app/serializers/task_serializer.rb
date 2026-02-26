class TaskSerializer
  def initialize(task)
    @task = task
  end

  def as_json(*)
    {
      id: @task.id,
      display_id: @task.display_id,
      title: @task.title,
      description: @task.description,
      priority: @task.priority,
      position: @task.position,
      due_date: @task.due_date,
      completed_at: @task.completed_at,
      status: {
        id: @task.task_status.id,
        name: @task.task_status.name,
        color: @task.task_status.color
      },
      assignee: @task.assignee ? { id: @task.assignee.id, name: @task.assignee.name } : nil,
      creator: { id: @task.creator.id, name: @task.creator.name },
      agent_identifier: @task.agent_identifier,
      blocked: @task.blocked?,
      comments_count: @task.comments.size,
      attachments_count: @task.attachments.size,
      created_at: @task.created_at.iso8601,
      updated_at: @task.updated_at.iso8601
    }
  end
end
