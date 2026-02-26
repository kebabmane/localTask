# frozen_string_literal: true

class ApplicationTool < ActionTool::Base
  private

  def current_user
    @current_user ||= User.find_by(role: :admin) || User.first
  end

  def find_project(identifier)
    Project.find_by(id: identifier) || Project.find_by!(prefix: identifier.to_s.upcase)
  end
end
