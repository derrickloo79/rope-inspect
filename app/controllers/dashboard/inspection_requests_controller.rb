module Dashboard
  class InspectionRequestsController < BaseController
    before_action :set_inspection_request, only: [
      :show, :edit, :update, :accept, :reject, :cancel, :abort, :reopen, :schedule, :hold, :complete, :site_access, :point_of_contact
    ]

    # Ref-no descending is the default and is omitted from the URL.
    # Assigned-date sorts stay off for All, Accepted, On Hold, and Rejected.
    SORT_VALUES = %w[asc date_asc date_desc].freeze
    DATE_SORTS = %w[date_asc date_desc].freeze
    DATE_SORT_STATUSES = %w[pending scheduled completed cancelled aborted].freeze

    helper_method :jobs_index_path, :jobs_list_params, :job_return_params

    def index
      @query = params[:q].to_s.strip.presence
      @status_filter = params[:status].presence_in(InspectionRequest::STATUSES)
      @sort = SORT_VALUES.include?(params[:sort]) ? params[:sort] : "desc"
      @date_sort_allowed = DATE_SORT_STATUSES.include?(@status_filter)
      if DATE_SORTS.include?(@sort) && !@date_sort_allowed
        redirect_to jobs_index_path(sort: "desc")
        return
      end
      counted = InspectionRequest.all
      counted = counted.matching_query(@query) if @query
      @status_counts = counted.group(:status).count
      @all_count = @status_counts.values.sum
      scope = counted
        .includes(:fsp, cranes: { lm_certificate_attachment: :blob, mill_certificates_attachments: :blob })
      scope = scope.where(status: @status_filter) if @status_filter
      @inspection_requests = apply_job_sort(scope)
    end

    def show
    end

    def edit
    end

    def update
      if @inspection_request.update(job_details_params)
        redirect_to job_show_path,
                    notice: "Inspection details updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def accept
      if @inspection_request.accept!(actor: current_user)
        redirect_to job_show_path,
                    notice: "Request accepted. A public status link is ready."
      else
        redirect_to job_show_path,
                    alert: "Could not accept this request from its current state."
      end
    end

    def reject
      if @inspection_request.reject!(actor: current_user)
        redirect_to job_show_path,
                    notice: "Request rejected."
      else
        redirect_to job_show_path,
                    alert: "Could not reject this request from its current state."
      end
    end

    def cancel
      reason = params.dig(:inspection_request, :cancellation_reason)
      if @inspection_request.cancel!(reason, actor: current_user)
        redirect_to job_show_path,
                    notice: "Job cancelled."
      elsif @inspection_request.errors[:cancellation_reason].any?
        @open_cancel_modal = true
        @cancellation_reason_input = reason
        render :show, status: :unprocessable_entity
      else
        redirect_to job_show_path,
                    alert: "Could not cancel this job from its current state."
      end
    end

    def abort
      reason = params.dig(:inspection_request, :abort_reason)
      if @inspection_request.abort!(reason, actor: current_user)
        redirect_to job_show_path,
                    notice: "Job aborted."
      elsif @inspection_request.errors[:abort_reason].any?
        @open_abort_modal = true
        @abort_reason_input = reason
        render :show, status: :unprocessable_entity
      else
        redirect_to job_show_path,
                    alert: "Could not abort this job from its current state."
      end
    end

    def reopen
      if @inspection_request.reopen!
        redirect_to job_show_path,
                    notice: "Request re-opened and moved back to pending."
      else
        redirect_to job_show_path,
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
      if @inspection_request.schedule!(on: on, at: at, fsp: fsp, actor: current_user)
        notice = was_on_hold ? "On hold removed. This job is scheduled again." : "Inspection scheduled."
        redirect_to after_schedule_path, notice: notice
      else
        redirect_to after_schedule_path,
                    alert: "Could not schedule from the current state. Accept the request first."
      end
    end

    def hold
      reason = params.dig(:inspection_request, :on_hold_reason)
      if @inspection_request.hold!(reason, actor: current_user)
        redirect_to job_show_path,
                    notice: "Job marked on hold."
      elsif @inspection_request.errors[:on_hold_reason].any?
        @open_on_hold_modal = true
        @on_hold_reason_input = reason
        render :show, status: :unprocessable_entity
      else
        redirect_to job_show_path,
                    alert: "Only a scheduled job can be marked on hold."
      end
    end

    def complete
      if @inspection_request.complete!(actor: current_user)
        redirect_to job_show_path,
                    notice: "Marked as completed."
      else
        redirect_to job_show_path,
                    alert: "Only scheduled inspections can be completed."
      end
    end

    def site_access
      if @inspection_request.completed? && !@inspection_request.site_access?
        redirect_to job_show_path,
                    alert: "Site access cannot be added after a job is completed."
      elsif @inspection_request.update(site_access_params)
        redirect_to job_show_path,
                    notice: "Site access details saved."
      else
        flash.now[:alert] = @inspection_request.errors.full_messages.to_sentence
        render :show, status: :unprocessable_entity
      end
    end

    def point_of_contact
      if @inspection_request.completed? && !@inspection_request.point_of_contact?
        redirect_to job_show_path,
                    alert: "A point of contact cannot be added after a job is completed."
      elsif @inspection_request.update(point_of_contact_params)
        redirect_to job_show_path,
                    notice: "Point of contact saved."
      else
        flash.now[:alert] = @inspection_request.errors.full_messages.to_sentence
        render :show, status: :unprocessable_entity
      end
    end

    private

    def set_inspection_request
      @inspection_request = InspectionRequest
        .includes(:fsp, { job_events: :user }, cranes: { lm_certificate_attachment: :blob, mill_certificates_attachments: :blob })
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

    # The list the admin was looking at, carried onto a job so All jobs can return there.
    def jobs_list_params
      sort = @sort == "desc" ? nil : @sort
      { status: @status_filter, q: @query, sort: sort }.compact
    end

    # Filter, search, and sort on the job page. After a form post, read them from
    # the page the form was submitted from so the return link stays intact.
    def job_return_params
      source = list_query_source
      status = list_param(source, :status).presence_in(InspectionRequest::STATUSES)
      q = list_param(source, :q).to_s.strip.presence
      sort = list_param(source, :sort).to_s
      sort = SORT_VALUES.include?(sort) ? sort : nil
      sort = nil if DATE_SORTS.include?(sort) && !DATE_SORT_STATUSES.include?(status)
      { status: status, q: q, sort: sort }.compact
    end

    def job_show_path
      dashboard_inspection_request_path(@inspection_request, job_return_params)
    end

    # Keeps the current search and drops a sort the destination filter cannot use.
    def jobs_index_path(status: @status_filter, q: @query, sort: @sort)
      sort = nil if sort.blank? || sort == "desc"
      sort = nil if DATE_SORTS.include?(sort) && !DATE_SORT_STATUSES.include?(status)
      dashboard_inspection_requests_path(status: status, q: q.presence, sort: sort)
    end

    def apply_job_sort(scope)
      case @sort
      when "asc"
        scope.order(id: :asc)
      when "date_asc"
        scope.order(Arel.sql("scheduled_on ASC NULLS LAST, scheduled_time ASC NULLS LAST, id ASC"))
      when "date_desc"
        scope.order(Arel.sql("scheduled_on DESC NULLS LAST, scheduled_time DESC NULLS LAST, id DESC"))
      else
        scope.order(id: :desc)
      end
    end

    def point_of_contact_params
      params.require(:inspection_request).permit(:poc_name, :poc_country_code, :poc_contact_number)
    end

    # Map AM/PM radio values to a time-of-day stored on scheduled_time.
    def list_query_source
      return params if request.get? || request.head?

      query = URI.parse(request.referer.to_s).query
      Rack::Utils.parse_query(query.to_s)
    rescue URI::InvalidURIError
      {}
    end

    def list_param(source, key)
      source[key] || source[key.to_s]
    end

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
        job_show_path
      end
    end
  end
end
