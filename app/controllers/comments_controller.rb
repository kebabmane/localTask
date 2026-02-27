class CommentsController < ApplicationController
  before_action :set_project
  before_action :set_task
  before_action :require_project_editor

  def create
    @comment = @task.comments.build(comment_params)
    @comment.user = Current.user

    if @comment.save
      respond_to do |format|
        format.html { redirect_to project_task_path(@project, @task) }
        format.turbo_stream
      end
    else
      redirect_to project_task_path(@project, @task), alert: "Comment could not be saved."
    end
  end

  def destroy
    @comment = @task.comments.find(params[:id])
    @comment.destroy

    respond_to do |format|
      format.html { redirect_to project_task_path(@project, @task) }
      format.turbo_stream
    end
  end

  private

  def set_project
    @project = Current.user.accessible_projects.find(params[:project_id])
  end

  def set_task
    @task = @project.tasks.find(params[:task_id])
  end

  def comment_params
    params.require(:comment).permit(:body, attachments: [])
  end
end
