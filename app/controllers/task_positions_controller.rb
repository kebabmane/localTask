class TaskPositionsController < ApplicationController
  def update
    @task = Task.find(params[:task_id])
    @project = @task.project

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
end
