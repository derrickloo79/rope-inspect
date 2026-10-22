module Dashboard
  class InspectionRequestsController < BaseController
    before_action :set_inspection_request, only: [
      :show, :edit, :update, :accept, :reject, :cancel, :abort, :reopen, :schedule, :hold, :complete, :site_access, :point_of_contact
    ]

    def index
      @query = params[:q].to_s.strip.presence
      @status_filter = params[:status].presence_in(InspectionRequest::STATUSES)
      # Reference codes are RI- plus the id, so id order is reference-number order.
      # Descending is the default and is omitted from the URL.
      @sort = params[:sort] == "asc" ? "asc" : "desc"
      counted = InspectionRequest.all
      counted = counted.matching_query(@query) if @query
      @status_counts = counted.group(:status).count
      @all_count = @status_counts.values.sum
      scope = counted
        .includes(:fsp, cranes: { lm_certificate_attachment: :blob, mill_certificates_attachments: :blob })
        .order(id: @sort == "asc" ? :asc : :desc)
      scope = scope.where(status: @status_filter) if @status_filter
      @inspection_requests = scope
    end

    def show
    end

    def edit
    end

    def update
      if @inspection_request.update(job_details_params)
        redirect_to dashboard_inspection_request_path(@inspection_request),
                    notice: "Inspection details updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def accept
      if @inspection_request.accept!
        redirect_to dashboard_inspection_request_path(@inspection_request),
                    notice: "Request accepted. A public status link is ready."
      else
        redirect_to dashboard_inspection_request_path(@inspection_request),
                    alert: "Could not accept this request from its current state."
      end
    end

    def reject
      if @inspection_request.reject!
        redirect_to dashboard_inspection_request_path(@inspection_request),
                    notice: "Request rejected."
      else
        redirect_to dashboard_inspection_request_path(@inspection_request),
                    alert: "Could not reject this request from its current state."
      end
    end

    def cancel
      reason = params.dig(:inspection_request, :cancellation_reason)
      if @inspection_request.cancel!(reason)
        redirect_to dashboard_inspection_request_path(@inspection_request),
                    notice: "Job cancelled."
      elsif @inspection_request.errors[:cancellation_reason].any?
        @open_cancel_modal = true
        @cancellation_reason_input = reason
        render :show, status: :unprocessable_entity
      else
        redirect_to dashboard_inspection_request_path(@inspection_request),
                    alert: "Could not cancel this job from its current state."
      end
    end

    def abort
      reason = params.dig(:inspection_request, :abort_reason)
      if @inspection_request.abort!(reason)
        redirect_to dashboard_inspection_request_path(@inspection_request),
                    notice: "Job aborted."
      elsif @inspection_request.errors[:abort_reason].any?
        @open_abort_modal = true
        @abort_reason_input = reason
        render :show, status: :unprocessable_entity
      else
        redirect_to dashboard_inspection_request_path(@inspection_request),
                    alert: "Could not abort this job from its current state."
      end
    end

    def reopen
      if @inspection_request.reopen!
        redirect_to dashboard_inspection_request_path(@inspection_request),
                    notice: "Request re-opened and moved back to pending."
      else
        redirect_to dashboard_inspection_request_path(@inspection_request),
                    alert: "Could not re-open this request from its current state."
      end
    end

    def schedule
      on = params.dig(:inspection_request, :scheduled_on).presence
      period = params.dig(:inspection_request, :scheduled_time).presence_in(%w[AM PM])
      at = period_to_time(period)
      fsp_id = params.dig(:inspection_request, :fsp_id).presence
      fsp = fsp_id.present? ? Fsp.find_by(id: fsp_id) : nil

      if on.blank?
        redirect_to after_schedule_path, alert: "Pick a schedule date."
        return
      end

      if period.blank?
        redirect_to after_schedule_path, alert: "Select a time (AM or PM)."
        return
      end

      if fsp_id.present? && fsp.nil?
        redirect_to after_schedule_path, alert: "Selected FSP was not found."
        return
      end

      was_on_hold = @inspection_request.on_hold?
      if @inspection_request.schedule!(on: on, at: at, fsp: fsp)
        notice = was_on_hold ? "On hold removed. This job is scheduled again." : "Inspection scheduled."
        redirect_to after_schedule_path, notice: notice
      else
        redirect_to after_schedule_path,
                    alert: "Could not schedule from the current state. Accept the request first."
      end
    end

    def hold
      reason = params.dig(:inspection_request, :on_hold_reason)
      if @inspection_request.hold!(reason)
        redirect_to dashboard_inspection_request_path(@inspection_request),
                    notice: "Job marked on hold."
      elsif @inspection_request.errors[:on_hold_reason].any?
        @open_on_hold_modal = true
        @on_hold_reason_input = reason
        render :show, status: :unprocessable_entity
      else
        redirect_to dashboard_inspection_request_path(@inspection_request),
                    alert: "Only a scheduled job can be marked on hold."
      end
    end

    def complete
      if @inspection_request.complete!
        redirect_to dashboard_inspection_request_path(@inspection_request),
                    notice: "Marked as completed."
      else
        redirect_to dashboard_inspection_request_path(@inspection_request),
                    alert: "Only scheduled inspections can be completed."
      end
    end

    def site_access
      if @inspection_request.completed? && !@inspection_request.site_access?
        redirect_to dashboard_inspection_request_path(@inspection_request),
                    alert: "Site access cannot be added after a job is completed."
      elsif @inspection_request.update(site_access_params)
        redirect_to dashboard_inspection_request_path(@inspection_request),
                    notice: "Site access details saved."
      else
        flash.now[:alert] = @inspection_request.errors.full_messages.to_sentence
        render :show, status: :unprocessable_entity
      end
    end

    def point_of_contact
      if @inspection_request.completed? && !@inspection_request.point_of_contact?
        redirect_to dashboard_inspection_request_path(@inspection_request),
                    alert: "A point of contact cannot be added after a job is completed."
      elsif @inspection_request.update(point_of_contact_params)
        redirect_to dashboard_inspection_request_path(@inspection_request),
                    notice: "Point of contact saved."
      else
        flash.now[:alert] = @inspection_request.errors.full_messages.to_sentence
        render :show, status: :unprocessable_entity
      end
    end

    private

    def set_inspection_request
      @inspection_request = InspectionRequest
        .includes(:fsp, cranes: { lm_certificate_attachment: :blob, mill_certificates_attachments: :blob })
        .find(params[:id])
    end

    def job_details_params
      params.require(:inspection_request).permit(
        :company_name,
        :requestor_name,
        :country_code,
        :contact_number,
        :site_name,
        cranes_attributes: [
          :id,
          :crane_type,
          :crane_type_other,
          :lm_number,
          :rope_diameter_mm,
          :position,
          :_destroy
        ]
      )
    end

    def site_access_params
      params.require(:inspection_request).permit(:map_url, :site_note)
    end

    def point_of_contact_params
      params.require(:inspection_request).permit(:poc_name, :poc_country_code, :poc_contact_number)
    end

    # Map AM/PM radio values to a time-of-day stored on scheduled_time.
    def period_to_time(period)
      case period
      when "AM" then Time.zone.parse("09:00")
      when "PM" then Time.zone.parse("14:00")
      end
    end

    # Stay on planner when scheduling from the planner modal.
    def after_schedule_path
      return_to = params[:return_to].presence || params.dig(:inspection_request, :return_to)
      if return_to == "planner"
        dashboard_planner_path(
          week: params[:week].presence || params.dig(:inspection_request, :week),
          fsp_id: params[:fsp_filter].presence || params.dig(:inspection_request, :fsp_filter)
        )
      else
        dashboard_inspection_request_path(@inspection_request)
      end
    end
  end
end
