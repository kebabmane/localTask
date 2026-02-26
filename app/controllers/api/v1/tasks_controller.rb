module Api
  module V1
    class TasksController < BaseController
      before_action :set_project
      before_action :set_task, only: [:show, :update, :destroy]

      def index
        tasks = @project.tasks.includes(:task_status, :assignee, :creator)
        tasks = tasks.where(task_status_id: params[:status_id]) if params[:status_id]
        tasks = tasks.where(priority: params[:priority]) if params[:priority]
        tasks = tasks.by_agent(params[:agent]) if params[:agent]
        tasks = tasks.ordered

        render json: tasks.map { |t| TaskSerializer.new(t).as_json }
      end

      def show
        render json: TaskDetailSerializer.new(@task).as_json
      end

      def create
        task = @project.tasks.build(task_params)
        task.creator = @current_user
        task.agent_identifier = request.headers["X-Agent-Identifier"]
        task.agent_session_id = request.headers["X-Agent-Session-Id"]
        task.save!

        render json: TaskSerializer.new(task).as_json, status: :created
      end

      def update
        @task.agent_identifier = request.headers["X-Agent-Identifier"] if request.headers["X-Agent-Identifier"]
        @task.update!(task_params)
        render json: TaskSerializer.new(@task).as_json
      end

      def destroy
        @task.destroy
        head :no_content
      end

      private

      def set_project
        @project = @current_user.projects.find(params[:project_id])
      end

      def set_task
        @task = @project.tasks.find(params[:id])
      end

      def task_params
        params.require(:task).permit(
          :title, :description, :priority, :due_date,
          :task_status_id, :assignee_id, :position
        )
      end
    end
  end
end
