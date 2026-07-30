module Dashboard
  class PlannerController < BaseController
    def index
      @week_start = parse_week_start(params[:week])
      @week_end = @week_start + 6.days
      @week_days = (@week_start..@week_end).to_a

      @accepted_jobs = InspectionRequest.accepted
        .includes(:cranes, :fsp)
        .order(Arel.sql("accepted_at DESC NULLS LAST"), created_at: :desc)

      @scheduled_by_day = InspectionRequest.scheduled
        .includes(:cranes, :fsp)
        .where(scheduled_on: @week_start..@week_end)
        .order(:scheduled_on, :scheduled_time, :company_name)
        .group_by(&:scheduled_on)
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
