module Portal
  class HomeController < BaseController
    def index
      # FSP dashboard: upcoming scheduled jobs for this inspector only.
      @upcoming_jobs = InspectionRequest.upcoming_within(7)
        .where(fsp_id: current_fsp.id)
        .includes(:cranes, :fsp)
      @upcoming_by_day = @upcoming_jobs.group_by(&:scheduled_on).transform_values do |jobs|
        jobs.sort_by(&:schedule_sort_key)
      end
    end
  end
end
