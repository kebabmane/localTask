class ApplicationController < ActionController::Base
  include Authentication
  include Authorization
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  helper_method :show_sidebar?

  def show_sidebar?
    authenticated? && !is_a?(SessionsController) && !is_a?(RegistrationsController) && !is_a?(PasswordsController)
  end
end
