module Dashboard
  class HomeController < BaseController
    def index
      @counts = {
        pending: InspectionRequest.pending.count,
        accepted: InspectionRequest.accepted.count,
        scheduled: InspectionRequest.scheduled.count,
        completed: InspectionRequest.completed.count
      }

      @upcoming_jobs = InspectionRequest.upcoming_within(7).includes(:cranes, :fsp)
      @upcoming_by_day = @upcoming_jobs.group_by(&:scheduled_on)
    end
  end
end
