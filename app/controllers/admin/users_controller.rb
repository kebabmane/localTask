module Admin
  class UsersController < BaseController
    before_action :set_user, only: [:show, :edit, :update]

    def index
      @users = User.includes(:projects, :api_tokens).order(created_at: :desc)
      if params[:q].present?
        @users = @users.where("name LIKE ? OR email_address LIKE ?",
                  "%#{params[:q]}%", "%#{params[:q]}%")
      end
    end

    def show
      @projects = @user.projects
      @api_tokens = @user.api_tokens.order(created_at: :desc)
      @recent_tasks = @user.created_tasks.includes(:project, :task_status)
                           .order(created_at: :desc).limit(10)
    end

    def edit
    end

    def update
      if params[:user][:role] == "user" && @user == Current.user
        redirect_to admin_user_path(@user), alert: "You cannot remove your own admin role."
        return
      end

      if @user.update(user_params)
        redirect_to admin_user_path(@user), notice: "User updated successfully."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def current_admin_section = :users

    def set_user
      @user = User.find(params[:id])
    end

    def user_params
      params.require(:user).permit(:name, :email_address, :role)
    end
  end
end
