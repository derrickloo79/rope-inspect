module Dashboard
  class FspsController < BaseController
    before_action :set_fsp, only: [ :show, :edit, :update, :destroy ]

    def index
      @fsps = Fsp.ordered
    end

    def show
      @jobs = @fsp.assigned_jobs.includes(:fsp)
    end

    def new
      @fsp = Fsp.new(date_joined: Date.current, country_code: Fsp::DEFAULT_COUNTRY_CODE)
    end

    def create
      @fsp = Fsp.new(fsp_params)
      if @fsp.save
        redirect_to dashboard_fsp_path(@fsp), notice: "#{@fsp.fsp_number} was created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      attrs = fsp_params
      password_changed = attrs[:password].present?
      if @fsp.update(attrs)
        notice = "#{@fsp.fsp_number} was updated."
        notice += " Login password was changed — they can sign in at /fsp/sign_in." if password_changed
        redirect_to dashboard_fsp_path(@fsp), notice: notice
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      label = @fsp.fsp_number
      @fsp.destroy!
      redirect_to dashboard_fsps_path, notice: "#{label} was deleted."
    end

    private

    def set_fsp
      @fsp = Fsp.find(params[:id])
    end

    def fsp_params
      permitted = params.require(:fsp).permit(
        :full_name,
        :country_code,
        :contact_number,
        :email,
        :date_joined,
        :color,
        :password,
        :password_confirmation
      )
      # Blank password on edit means "leave unchanged" (Devise still validates empty strings).
      if permitted[:password].blank?
        permitted = permitted.except(:password, :password_confirmation)
      end
      permitted
    end
  end
end
