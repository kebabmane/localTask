class TasksController < ApplicationController
  before_action :set_project
  before_action :set_task, only: [:show, :edit, :update, :destroy]

  def show
    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  def new
    @task = @project.tasks.build
    @task.task_status = @project.task_statuses.default_status.first
  end

  def create
    @task = @project.tasks.build(task_params)
    @task.creator = Current.user

    if @task.save
      respond_to do |format|
        format.html { redirect_to project_board_path(@project), notice: "Task created." }
        format.turbo_stream
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @task.update(task_params)
      respond_to do |format|
        format.html { redirect_to project_task_path(@project, @task), notice: "Task updated." }
        format.turbo_stream
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @task.destroy
    respond_to do |format|
      format.html { redirect_to project_board_path(@project), notice: "Task deleted." }
      format.turbo_stream
    end
  end

  private

  def set_project
    @project = Current.user.projects.find(params[:project_id])
  end

  def set_task
    @task = @project.tasks.find(params[:id])
  end

  def task_params
    params.require(:task).permit(
      :title, :description, :priority, :due_date,
      :task_status_id, :assignee_id, attachments: []
    )
  end
end
