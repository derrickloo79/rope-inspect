module Dashboard
  class FspsController < BaseController
    before_action :set_fsp, only: [ :edit, :update, :destroy ]

    def index
      @fsps = Fsp.ordered
    end

    def new
      @fsp = Fsp.new(date_joined: Date.current, country_code: Fsp::DEFAULT_COUNTRY_CODE)
    end

    def create
      @fsp = Fsp.new(fsp_params)
      if @fsp.save
        redirect_to dashboard_fsps_path, notice: "#{@fsp.fsp_number} was created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @fsp.update(fsp_params)
        redirect_to dashboard_fsps_path, notice: "#{@fsp.fsp_number} was updated."
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
