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

    helper_method :jobs_index_path

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
      before = crane_audit_rows(@inspection_request.cranes)
      if @inspection_request.update(job_details_params)
        summary = crane_details_change_summary(before, crane_audit_rows(@inspection_request.cranes.reload))
        if summary.present?
          @inspection_request.log_job_event!(
            "crane_details_updated",
            actor: current_user,
            details: { "summary" => summary }
          )
        end
        redirect_to dashboard_inspection_request_path(@inspection_request),
                    notice: "Inspection details updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def accept
      if @inspection_request.accept!(actor: current_user)
        redirect_to dashboard_inspection_request_path(@inspection_request),
                    notice: "Request accepted. A public status link is ready."
      else
        redirect_to dashboard_inspection_request_path(@inspection_request),
                    alert: "Could not accept this request from its current state."
      end
    end

    def reject
      if @inspection_request.reject!(actor: current_user)
        redirect_to dashboard_inspection_request_path(@inspection_request),
                    notice: "Request rejected."
      else
        redirect_to dashboard_inspection_request_path(@inspection_request),
                    alert: "Could not reject this request from its current state."
      end
    end

    def cancel
      reason = params.dig(:inspection_request, :cancellation_reason)
      if @inspection_request.cancel!(reason, actor: current_user)
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
      if @inspection_request.abort!(reason, actor: current_user)
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
      if @inspection_request.complete!(actor: current_user)
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
        log_detail_update!("site_access_updated", %w[map_url site_note]) do
          @inspection_request.site_access_audit_summary
        end
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
        log_detail_update!("poc_updated", %w[poc_name poc_country_code poc_contact_number]) do
          @inspection_request.poc_audit_summary
        end
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

    def log_detail_update!(action, attributes)
      return unless (attributes & @inspection_request.saved_changes.keys).any?

      @inspection_request.log_job_event!(action, actor: current_user, details: { "summary" => yield })
    end

    def crane_audit_rows(cranes)
      cranes.map do |crane|
        {
          id: crane.id,
          type: crane.crane_type_label,
          lm: crane.lm_number,
          diameter: crane.rope_diameter_mm.to_s
        }
      end
    end

    # One group per added, removed, or changed crane. Unchanged cranes are skipped.
    def crane_details_change_summary(before, after)
      before_by_id = before.index_by { |row| row[:id] }
      groups = []

      before.each do |old|
        next if after.any? { |row| row[:id] == old[:id] }

        groups << [ "Removed #{old[:type]} · #{old[:lm]}" ]
      end

      after.each do |current|
        old = before_by_id[current[:id]]
        if old.nil?
          groups << [ "Added #{current[:type]} · #{current[:lm]} · #{current[:diameter]} mm" ]
          next
        end

        diffs = []
        diffs << "Type #{old[:type]} → #{current[:type]}" if old[:type] != current[:type]
        diffs << "LM number #{old[:lm]} → #{current[:lm]}" if old[:lm] != current[:lm]
        if old[:diameter] != current[:diameter]
          diffs << "Rope diameter #{old[:diameter]} mm → #{current[:diameter]} mm"
        end
        next if diffs.empty?

        groups << [ "#{current[:type]} · #{current[:lm]}", *diffs ]
      end

      groups.map { |lines| lines.join("\n") }.join("\n\n").presence
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
