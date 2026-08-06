module Dashboard
  class CranesController < BaseController
    before_action :set_crane

    def update
      # Optional attachments — admin can add/replace later.
      if @crane.update(crane_cert_params)
        redirect_to dashboard_inspection_request_path(@crane.inspection_request),
                    notice: "Certificates updated for #{@crane.crane_type_label} (#{@crane.lm_number})."
      else
        redirect_to dashboard_inspection_request_path(@crane.inspection_request),
                    alert: @crane.errors.full_messages.to_sentence.presence || "Could not update certificates."
      end
    end

    private

    def set_crane
      @crane = Crane.find(params[:id])
    end

    def crane_cert_params
      permitted = params.require(:crane).permit(
        :lm_certificate,
        mill_certificates: [],
        remove_mill_certificate_ids: []
      )

      if permitted[:remove_mill_certificate_ids].present?
        ids = Array(permitted[:remove_mill_certificate_ids]).reject(&:blank?)
        @crane.mill_certificates.attachments.where(id: ids).find_each(&:purge)
      end

      # Ignore empty file inputs so we don't clear existing attachments.
      permitted = permitted.except(:lm_certificate) if permitted[:lm_certificate].blank?
      mills = Array(permitted[:mill_certificates]).reject(&:blank?)
      permitted =
        if mills.any?
          permitted.merge(mill_certificates: mills)
        else
          permitted.except(:mill_certificates)
        end

      permitted.except(:remove_mill_certificate_ids)
    end
  end
end
