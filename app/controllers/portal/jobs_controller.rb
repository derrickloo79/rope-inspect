module Portal
  class JobsController < BaseController
    before_action :set_job, only: :show

    def index
      @status_filter = params[:status].presence_in(InspectionRequest::STATUSES)
      scope = current_fsp.assigned_jobs
      scope = scope.where(status: @status_filter) if @status_filter
      @jobs = scope
      @counts = current_fsp.inspection_requests.group(:status).count
    end

    def show
    end

    private

    def set_job
      @job = current_fsp.assigned_jobs.find(params[:id])
    end
  end
end
