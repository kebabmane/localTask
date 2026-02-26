class DashboardsController < ApplicationController
  def show
    @projects = Current.user.projects.active.includes(:task_statuses, :tasks).order(:position)
  end
end
