module Dashboard
  class InspectionRequestsController < BaseController
    before_action :set_inspection_request, only: [
      :show, :accept, :reject, :reopen, :schedule, :complete, :site_access, :point_of_contact
    ]

    def index
      @status_filter = params[:status].presence_in(InspectionRequest::STATUSES)
      scope = InspectionRequest.includes(:cranes, :fsp).recent_first
      scope = scope.where(status: @status_filter) if @status_filter
      @inspection_requests = scope
      @counts = InspectionRequest.group(:status).count
    end

    def show
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

      if @inspection_request.schedule!(on: on, at: at, fsp: fsp)
        redirect_to after_schedule_path, notice: "Inspection scheduled."
      else
        redirect_to after_schedule_path,
                    alert: "Could not schedule from the current state. Accept the request first."
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
      if @inspection_request.update(site_access_params)
        redirect_to dashboard_inspection_request_path(@inspection_request),
                    notice: "Site access details saved."
      else
        flash.now[:alert] = @inspection_request.errors.full_messages.to_sentence
        render :show, status: :unprocessable_entity
      end
    end

    def point_of_contact
      if @inspection_request.update(point_of_contact_params)
        redirect_to dashboard_inspection_request_path(@inspection_request),
                    notice: "Point of contact saved."
      else
        flash.now[:alert] = @inspection_request.errors.full_messages.to_sentence
        render :show, status: :unprocessable_entity
      end
    end

    private

    def set_inspection_request
      @inspection_request = InspectionRequest.includes(:cranes, :fsp).find(params[:id])
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
