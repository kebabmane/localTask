module Api
  module V1
    class TaskStatusesController < BaseController
      before_action :set_project

      # GET /api/v1/projects/:project_id/statuses
      def index
        statuses = @project.task_statuses.ordered
        render json: statuses.map { |s|
          { id: s.id, name: s.name, color: s.color, position: s.position,
            is_default: s.is_default, is_closed: s.is_closed }
        }
      end

      # PATCH /api/v1/projects/:project_id/tasks/:task_id/status
      def update
        task = @project.tasks.find(params[:task_id])
        new_status = @project.task_statuses.find_by!(name: params[:status]) if params[:status]
        new_status ||= @project.task_statuses.find(params[:status_id]) if params[:status_id]

        task.update!(task_status: new_status)
        render json: TaskSerializer.new(task).as_json
      end

      private

      def set_project
        @project = @current_user.accessible_projects.find(params[:project_id])
      end
    end
  end
end
