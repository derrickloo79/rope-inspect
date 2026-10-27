module Dashboard
  class CranesController < BaseController
    before_action :set_crane

    def update
      if params[:crane]&.key?(:remarks)
        update_remarks
      else
        update_certificates_action
      end
    end

    private

    def set_crane
      @crane = Crane.find(params[:id])
    end

    def update_remarks
      if @crane.inspection_request.completed? && @crane.remarks.blank?
        redirect_to dashboard_inspection_request_path(@crane.inspection_request),
                    alert: "Crane remarks cannot be added after a job is completed."
      elsif @crane.update(params.require(:crane).permit(:remarks))
        if @crane.saved_changes.key?("remarks")
          @crane.inspection_request.log_job_event!(
            "crane_remarks_updated",
            actor: current_user,
            details: { "summary" => @crane.remarks_audit_summary }
          )
        end
        redirect_to dashboard_inspection_request_path(@crane.inspection_request),
                    notice: "Remarks saved for #{@crane.crane_type_label} (#{@crane.lm_number})."
      else
        redirect_to dashboard_inspection_request_path(@crane.inspection_request),
                    alert: @crane.errors.full_messages.to_sentence.presence || "Could not save remarks."
      end
    end

    def update_certificates_action
      # Optional attachments — admin can add/replace LM, append mills, remove by id.
      changes = update_certificates
      if changes
        if changes.any?
          @crane.inspection_request.log_job_event!(
            "crane_certificates_updated",
            actor: current_user,
            details: { "summary" => ([ @crane.audit_heading ] + changes).join("\n") }
          )
        end
        redirect_to dashboard_inspection_request_path(@crane.inspection_request),
                    notice: "Certificates updated for #{@crane.crane_type_label} (#{@crane.lm_number})."
      else
        redirect_to dashboard_inspection_request_path(@crane.inspection_request),
                    alert: @crane.errors.full_messages.to_sentence.presence || "Could not update certificates."
      end
    end

    # Returns the list of file changes, or nil when the crane is invalid.
    def update_certificates
      permitted = params.require(:crane).permit(
        :lm_certificate,
        :remove_lm_certificate,
        mill_certificates: [],
        remove_mill_certificate_ids: []
      )
      changes = []

      if permitted[:remove_mill_certificate_ids].present?
        ids = Array(permitted[:remove_mill_certificate_ids]).reject(&:blank?)
        @crane.mill_certificates.attachments.where(id: ids).find_each do |attachment|
          changes << "Removed mill certificate #{audit_filename(attachment.filename)}"
          attachment.purge
        end
      end

      remove_lm = ActiveModel::Type::Boolean.new.cast(permitted[:remove_lm_certificate])
      if remove_lm && permitted[:lm_certificate].blank? && @crane.lm_certificate.attached?
        changes << "Removed LM certificate #{audit_filename(@crane.lm_certificate.filename)}"
        @crane.lm_certificate.purge
      end

      # Append new mill files — never replace existing ones via mass-assignment.
      mills = Array(permitted[:mill_certificates]).reject(&:blank?)
      if mills.any?
        mills.each do |file|
          changes << "Added mill certificate #{audit_filename(file.original_filename)}"
        end
        @crane.mill_certificates.attach(mills)
      end

      # LM is has_one_attached: assign only when a new file is present (replaces).
      if permitted[:lm_certificate].present?
        filename = audit_filename(permitted[:lm_certificate].original_filename)
        if @crane.lm_certificate.attached?
          previous = audit_filename(@crane.lm_certificate.filename)
          changes << "Replaced LM certificate #{previous} with #{filename}"
        else
          changes << "Added LM certificate #{filename}"
        end
        @crane.lm_certificate.attach(permitted[:lm_certificate])
      end

      # Re-run model validations (content type / size) after attaching.
      @crane.valid?
      return nil if @crane.errors.any?

      changes
    end

    def audit_filename(name)
      name.to_s.gsub(/[\r\n]+/, " ").strip.presence || "file"
    end
  end
end
