module Api
  module V1
    class CommentsController < BaseController
      before_action :set_project
      before_action :set_task

      def index
        comments = @task.comments.order(:created_at)
        render json: comments.map { |c| CommentSerializer.new(c).as_json }
      end

      def create
        comment = @task.comments.build(comment_params)
        comment.user = @current_user unless request.headers["X-Agent-Identifier"]
        comment.agent_identifier = request.headers["X-Agent-Identifier"]
        comment.agent_session_id = request.headers["X-Agent-Session-Id"]
        comment.save!

        render json: CommentSerializer.new(comment).as_json, status: :created
      end

      private

      def set_project
        @project = @current_user.projects.find(params[:project_id])
      end

      def set_task
        @task = @project.tasks.find(params[:task_id])
      end

      def comment_params
        params.require(:comment).permit(:body)
      end
    end
  end
end
