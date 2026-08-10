module Dashboard
  class CranesController < BaseController
    before_action :set_crane

    def update
      # Optional attachments — admin can add/replace LM, append mills, remove by id.
      if update_certificates
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

    def update_certificates
      permitted = params.require(:crane).permit(
        :lm_certificate,
        :remove_lm_certificate,
        mill_certificates: [],
        remove_mill_certificate_ids: []
      )

      if permitted[:remove_mill_certificate_ids].present?
        ids = Array(permitted[:remove_mill_certificate_ids]).reject(&:blank?)
        @crane.mill_certificates.attachments.where(id: ids).find_each(&:purge)
      end

      remove_lm = ActiveModel::Type::Boolean.new.cast(permitted[:remove_lm_certificate])
      if remove_lm && permitted[:lm_certificate].blank? && @crane.lm_certificate.attached?
        @crane.lm_certificate.purge
      end

      # Append new mill files — never replace existing ones via mass-assignment.
      mills = Array(permitted[:mill_certificates]).reject(&:blank?)
      @crane.mill_certificates.attach(mills) if mills.any?

      # LM is has_one_attached: assign only when a new file is present (replaces).
      if permitted[:lm_certificate].present?
        @crane.lm_certificate.attach(permitted[:lm_certificate])
      end

      # Re-run model validations (content type / size) after attaching.
      @crane.valid?
      @crane.errors.empty?
    end
  end
end
