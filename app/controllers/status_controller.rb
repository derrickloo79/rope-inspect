class StatusController < ApplicationController
  layout "public_status"

  # Public shareable status page for accepted (and later) jobs.
  def show
    @inspection_request = InspectionRequest.find_by!(share_token: params[:token])

    unless @inspection_request.public_status?
      raise ActiveRecord::RecordNotFound
    end
  end
end
