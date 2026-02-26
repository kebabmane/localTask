module Api
  module V1
    class ProjectsController < BaseController
      def index
        projects = @current_user.projects.active.includes(:task_statuses).order(:position)
        render json: projects.map { |p| ProjectSerializer.new(p).as_json }
      end

      def show
        project = @current_user.projects.find(params[:id])
        render json: ProjectDetailSerializer.new(project).as_json
      end

      def create
        project = @current_user.projects.build(project_params)
        project.save!
        render json: ProjectSerializer.new(project).as_json, status: :created
      end

      def update
        project = @current_user.projects.find(params[:id])
        project.update!(project_params)
        render json: ProjectSerializer.new(project).as_json
      end

      private

      def project_params
        params.require(:project).permit(:name, :description, :prefix, :color, :icon)
      end
    end
  end
end
