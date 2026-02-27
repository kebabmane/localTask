class ProjectMembersController < ApplicationController
  before_action :set_project
  before_action :require_project_manager

  def index
    @members = @project.project_members.includes(:user).order(:created_at)
  end

  def create
    user = User.find_by(email_address: params[:email_address])

    unless user
      redirect_to project_members_path(@project), alert: "No user found with that email address."
      return
    end

    if user.id == @project.user_id
      redirect_to project_members_path(@project), alert: "The project owner is already a member."
      return
    end

    member = @project.project_members.build(user: user, role: params[:role] || :viewer)

    if member.save
      redirect_to project_members_path(@project), notice: "#{user.name} added as #{member.role}."
    else
      redirect_to project_members_path(@project), alert: member.errors.full_messages.join(", ")
    end
  end

  def destroy
    member = @project.project_members.find(params[:id])
    member.destroy
    redirect_to project_members_path(@project), notice: "Member removed."
  end

  private

  def set_project
    @project = Current.user.accessible_projects.find(params[:project_id])
  end
end
