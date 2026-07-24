class InspectionRequestsController < ApplicationController
  # Public intake form — no authentication required.
  def new
    @inspection_request = InspectionRequest.new
    @inspection_request.cranes.build(crane_type: "tower_crane")
  end

  def create
    @inspection_request = InspectionRequest.new(inspection_request_params)
    @inspection_request.status = "pending"

    if @inspection_request.save
      redirect_to thank_you_inspection_requests_path(ref: @inspection_request.reference_code),
                  notice: "Your inspection request has been received."
    else
      if @inspection_request.cranes.empty?
        @inspection_request.cranes.build(crane_type: "tower_crane")
      end
      render :new, status: :unprocessable_entity
    end
  end

  def thank_you
    @reference_code = params[:ref]
  end

  private

  def inspection_request_params
    params.require(:inspection_request).permit(
      :company_name,
      :requestor_name,
      :contact_number,
      :site_name,
      cranes_attributes: [ :id, :crane_type, :lm_number, :rope_diameter_mm, :position, :_destroy ]
    )
  end
end
