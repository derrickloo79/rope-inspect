module Dashboard
  class PlannerController < BaseController
    def index
      @week_start = parse_week_start(params[:week])
      @week_end = @week_start + 6.days
      @week_days = (@week_start..@week_end).to_a
      @fsps = Fsp.ordered
      @fsp_filter = params[:fsp_id].presence
      @fsp_filter = nil unless @fsp_filter.present? && @fsps.any? { |f| f.id.to_s == @fsp_filter.to_s }

      @accepted_jobs = InspectionRequest.accepted
        .includes(:cranes, :fsp)
        .order(Arel.sql("accepted_at DESC NULLS LAST"), created_at: :desc)

      scheduled = InspectionRequest.scheduled
        .includes(:cranes, :fsp)
        .where(scheduled_on: @week_start..@week_end)
        .order(:scheduled_on, :scheduled_time, :company_name)
      scheduled = scheduled.where(fsp_id: @fsp_filter) if @fsp_filter.present?

      @scheduled_by_day = scheduled.group_by(&:scheduled_on)
    end

    private

    def parse_week_start(param)
      date = param.present? ? Date.iso8601(param) : Date.current
      date.beginning_of_week(:monday)
    rescue Date::Error, ArgumentError
      Date.current.beginning_of_week(:monday)
    end
  end
end
