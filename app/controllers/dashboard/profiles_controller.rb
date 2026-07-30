module Dashboard
  class ProfilesController < BaseController
    before_action :set_user

    def edit
    end

    def update
      attrs = profile_params
      password_changed = attrs[:password].present?
      if @user.update(attrs)
        notice = "Your profile was updated."
        notice += " Password was changed." if password_changed
        bypass_sign_in(@user) if password_changed
        redirect_to edit_dashboard_profile_path, notice: notice
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def set_user
      @user = current_user
    end

    def profile_params
      permitted = params.require(:user).permit(
        :name,
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
