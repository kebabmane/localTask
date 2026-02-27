class TaskPositionsController < ApplicationController
  before_action :set_project_and_task
  before_action :require_project_editor

  def update
    new_status_id = params[:task_status_id].to_i
    new_position = params[:position].to_i

    old_status_id = @task.task_status_id

    if old_status_id != new_status_id
      @task.update!(task_status_id: new_status_id)
      @task.insert_at(new_position)
    else
      @task.insert_at(new_position)
    end

    respond_to do |format|
      format.turbo_stream
      format.json { render json: { id: @task.id, status_id: @task.task_status_id, position: @task.position } }
    end
  end

  private

  def set_project_and_task
    @project = Current.user.accessible_projects.find(params[:project_id])
    @task = @project.tasks.find(params[:task_id])
  end
end
