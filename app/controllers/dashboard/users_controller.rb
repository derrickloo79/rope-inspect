module Dashboard
  class UsersController < BaseController
    before_action :set_user, only: [ :edit, :update, :destroy ]

    def index
      @users = User.ordered
    end

    def new
      @user = User.new(country_code: User::DEFAULT_COUNTRY_CODE)
    end

    def create
      @user = User.new(user_params)
      if @user.save
        redirect_to dashboard_users_path, notice: "#{@user.display_name} was created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      attrs = user_params
      password_changed = attrs[:password].present?
      if @user.update(attrs)
        notice = "#{@user.display_name} was updated."
        notice += " Password was changed." if password_changed
        redirect_to dashboard_users_path, notice: notice
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      if @user == current_user
        redirect_to dashboard_users_path, alert: "You cannot delete your own account."
        return
      end

      if User.count <= 1
        redirect_to dashboard_users_path, alert: "Cannot delete the last admin account."
        return
      end

      label = @user.display_name
      @user.destroy!
      redirect_to dashboard_users_path, notice: "#{label} was deleted."
    end

    private

    def set_user
      @user = User.find(params[:id])
    end

    def user_params
      permitted = params.require(:user).permit(
        :name,
        :email,
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
