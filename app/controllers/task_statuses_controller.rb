class TaskStatusesController < ApplicationController
  before_action :set_project

  def create
    @status = @project.task_statuses.build(status_params)

    if @status.save
      redirect_to project_board_path(@project), notice: "Status added."
    else
      redirect_to project_board_path(@project), alert: @status.errors.full_messages.join(", ")
    end
  end

  def update
    @status = @project.task_statuses.find(params[:id])

    if @status.update(status_params)
      redirect_to project_board_path(@project), notice: "Status updated."
    else
      redirect_to project_board_path(@project), alert: @status.errors.full_messages.join(", ")
    end
  end

  def destroy
    @status = @project.task_statuses.find(params[:id])

    if @status.destroy
      redirect_to project_board_path(@project), notice: "Status removed."
    else
      redirect_to project_board_path(@project), alert: @status.errors.full_messages.join(", ")
    end
  end

  private

  def set_project
    @project = Current.user.projects.find(params[:project_id])
  end

  def status_params
    params.require(:task_status).permit(:name, :color, :position, :is_default, :is_closed)
  end
end
