module Portal
  class JobsController < BaseController
    FILTERS = %w[scheduled completed].freeze

    before_action :set_job, only: :show

    def index
      @status_filter = params[:status].presence_in(FILTERS)
      scope = current_fsp.assigned_jobs.includes(:cranes, :fsp).recent_first
      scope = scope.where(status: @status_filter) if @status_filter
      @jobs = scope
      @counts = current_fsp.inspection_requests.group(:status).count
      @all_count = @counts.values.sum
    end

    def show
    end

    private

    def set_job
      @job = current_fsp.assigned_jobs
                        .includes(cranes: { lm_certificate_attachment: :blob, mill_certificates_attachments: :blob })
                        .find(params[:id])
    end
  end
end
