class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  private

  def after_sign_in_path_for(resource)
    case resource
    when Fsp
      portal_root_path
    else
      dashboard_root_path
    end
  end

  def after_sign_out_path_for(resource_or_scope)
    case resource_or_scope
    when :fsp, Fsp
      new_fsp_session_path
    else
      root_path
    end
  end
end
