module Dashboard
  class HomeController < BaseController
    def index
      @counts = {
        pending: InspectionRequest.pending.count,
        on_hold: InspectionRequest.on_hold.count,
        accepted: InspectionRequest.accepted.count,
        scheduled: InspectionRequest.scheduled.count,
        completed: InspectionRequest.completed.count
      }

      @fsps = Fsp.ordered
      @fsp_filter = params[:fsp_id].presence
      @fsp_filter = nil unless @fsp_filter.present? && @fsps.any? { |fsp| fsp.id.to_s == @fsp_filter.to_s }

      @upcoming_jobs = InspectionRequest.upcoming_within(7).includes(:cranes, :fsp)
      @upcoming_jobs = @upcoming_jobs.where(fsp_id: @fsp_filter) if @fsp_filter.present?
      @upcoming_by_day = @upcoming_jobs.group_by(&:scheduled_on).transform_values do |jobs|
        jobs.sort_by(&:schedule_sort_key)
      end
    end
  end
end
