module Dashboard
  # Soft check: is this FSP already booked for the same date + AM/PM session?
  class ScheduleSessionChecksController < BaseController
    def show
      date = parse_date(params[:scheduled_on])
      period = params[:scheduled_time].to_s.upcase.presence_in(%w[AM PM])
      fsp_id = params[:fsp_id].presence
      exclude_id = params[:exclude_id].presence

      if date.blank? || period.blank? || fsp_id.blank?
        render json: { conflict: false }
        return
      end

      conflict = InspectionRequest.find_fsp_session_conflict(
        fsp_id: fsp_id,
        date: date,
        period: period,
        exclude_id: exclude_id
      )

      if conflict
        fsp_label = conflict.fsp&.display_name.presence || "This inspector"
        render json: {
          conflict: true,
          message: "#{fsp_label} already has a job in the #{period} session on #{date.strftime('%-d %b %Y')}: " \
                   "#{conflict.site_name} (#{conflict.reference_code}). " \
                   "You can still assign them if needed."
        }
      else
        render json: { conflict: false }
      end
    end

    private

    def parse_date(value)
      return nil if value.blank?

      Date.iso8601(value.to_s)
    rescue Date::Error, ArgumentError
      Date.parse(value.to_s)
    rescue Date::Error, ArgumentError
      nil
    end
  end
end
