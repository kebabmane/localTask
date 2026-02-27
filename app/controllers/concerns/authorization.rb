module Authorization
  extend ActiveSupport::Concern

  private

  def require_project_editor
    unless @project.can_edit?(Current.user)
      redirect_back fallback_location: root_path, alert: "You don't have permission to edit this project."
    end
  end

  def require_project_manager
    unless @project.can_manage?(Current.user)
      redirect_back fallback_location: root_path, alert: "You don't have permission to manage this project."
    end
  end
end
