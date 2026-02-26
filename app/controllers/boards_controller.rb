class BoardsController < ApplicationController
  def show
    @project = Current.user.projects.find(params[:project_id])
    tasks = @project.tasks.includes(:task_status, :assignee, :creator).ordered
    @tasks_by_status = tasks.group_by(&:task_status_id)
  end
end
