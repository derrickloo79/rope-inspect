module Dashboard
  class InspectionRequestsController < BaseController
    before_action :set_inspection_request, only: [ :show, :accept, :reject, :schedule, :complete ]

    def index
      @status_filter = params[:status].presence_in(InspectionRequest::STATUSES)
      scope = InspectionRequest.includes(:cranes).recent_first
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

    def schedule
      on = params.dig(:inspection_request, :scheduled_on).presence
      period = params.dig(:inspection_request, :scheduled_time).presence_in(%w[AM PM])
      at = period_to_time(period)
      inspector = params.dig(:inspection_request, :assigned_inspector).presence

      if on.blank?
        redirect_to dashboard_inspection_request_path(@inspection_request),
                    alert: "Pick a schedule date."
        return
      end

      if @inspection_request.schedule!(on: on, at: at, inspector: inspector)
        redirect_to dashboard_inspection_request_path(@inspection_request),
                    notice: "Inspection scheduled."
      else
        redirect_to dashboard_inspection_request_path(@inspection_request),
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

    private

    def set_inspection_request
      @inspection_request = InspectionRequest.includes(:cranes).find(params[:id])
    end

    # Map AM/PM radio values to a time-of-day stored on scheduled_time.
    def period_to_time(period)
      case period
      when "AM" then Time.zone.parse("09:00")
      when "PM" then Time.zone.parse("14:00")
      end
    end
  end
end
