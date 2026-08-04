module Portal
  class ProfilesController < BaseController
    before_action :set_fsp

    def edit
    end

    def update
      attrs = profile_params
      password_changed = attrs[:password].present?
      if @fsp.update(attrs)
        notice = "Your profile was updated."
        notice += " Password was changed." if password_changed
        # Keep session valid after password change (Devise multi-model scope).
        bypass_sign_in(@fsp, scope: :fsp) if password_changed
        redirect_to edit_portal_profile_path, notice: notice
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def set_fsp
      @fsp = current_fsp
    end

    def profile_params
      permitted = params.require(:fsp).permit(
        :full_name,
        :country_code,
        :contact_number,
        :password,
        :password_confirmation
      )
      if permitted[:password].blank?
        permitted = permitted.except(:password, :password_confirmation)
      end
      permitted
    end
  end
end
