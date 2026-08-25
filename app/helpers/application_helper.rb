module ApplicationHelper
  def nav_link_active?(section)
    case section
    when :dashboard
      controller_path == "dashboard/home"
    when :planner
      controller_path == "dashboard/planner"
    when :fsps
      controller_path == "dashboard/fsps"
    when :admins
      controller_path == "dashboard/users"
    when :profile
      controller_path == "dashboard/profiles"
    when :jobs
      controller_path == "dashboard/inspection_requests"
    when :portal_dashboard
      controller_path == "portal/home"
    when :portal_jobs
      controller_path == "portal/jobs"
    when :portal_profile
      controller_path == "portal/profiles"
    when :public_form
      controller_path == "inspection_requests" || controller_path == "status"
    else
      false
    end
  end

  def format_week_range(week_start, week_end = week_start + 6.days)
    start_date = week_start.to_date
    end_date = week_end.to_date

    if start_date.year == end_date.year
      "#{start_date.strftime('%-d %b')} – #{end_date.strftime('%-d %b')}"
    else
      "#{start_date.strftime('%-d %b, %y')} – #{end_date.strftime('%-d %b, %y')}"
    end
  end

  def site_header_link_class(section)
    classes = [ "site-header-link" ]
    classes << "is-active" if nav_link_active?(section)
    classes.join(" ")
  end

  # Greeting for FSP portal (Singapore time via app time zone).
  def greeting_for_time(time = Time.zone.now)
    hour = time.hour
    if hour < 12
      "Good morning"
    elsif hour < 18
      "Good afternoon"
    else
      "Good evening"
    end
  end


  # Country dial codes for selects: closed shows "+65", open shows "Singapore (+65)".
  # Used with data-controller="country-code-select".
  def country_code_select_options(selected = nil)
    options = Fsp::COUNTRY_CODES.map do |label, code|
      [ code, code, { data: { full: label, short: code } } ]
    end
    options_for_select(options, selected.presence || Fsp::DEFAULT_COUNTRY_CODE)
  end

  def country_code_select_html_options(extra = {})
    {
      class: "field-select country-code-select",
      required: true,
      aria: { label: "Country code" },
      data: {
        country_code_select_target: "select",
        action: [
          "focus->country-code-select#expand",
          "mousedown->country-code-select#expand",
          "change->country-code-select#collapseSelected",
          "blur->country-code-select#collapseSelected"
        ].join(" ")
      }
    }.deep_merge(extra)
  end

  # Browser key for Google Places Autocomplete (HTTP referrer restricted).
  # Set GOOGLE_MAPS_API_KEY or credentials.google_maps_api_key.
  def google_maps_api_key
    ENV["GOOGLE_MAPS_API_KEY"].presence ||
      Rails.application.credentials.dig(:google_maps_api_key).presence
  end


  # Avatar initials from a person's name: "Frederick Francis" → "FF".
  def initials_for(name)
    words = name.to_s.split(/[\s.\-]+/).reject(&:blank?)
    return "—" if words.empty?

    (words.first(2).map { |word| word[0] }.join).upcase
  end

  # wa.me deep link — opens the WhatsApp app on mobile, WhatsApp Web on desktop.
  # Expects a digits-only number with country code (e.g. InspectionRequest#whatsapp_number).
  # Pass `text:` to pre-fill the message body (e.g. job details to send the requestor).
  def whatsapp_href(number, text: nil)
    digits = number.to_s.gsub(/\D/, "")
    return nil if digits.blank?

    href = "https://wa.me/#{digits}"
    href += "?text=#{ERB::Util.url_encode(text)}" if text.present?
    href
  end

  # Pre-filled WhatsApp message for the "Send job details" menu action.
  def job_details_whatsapp_message(inspection_request)
    lines = [
      "Hi #{inspection_request.requestor_name},",
      "Here are your inspection job details:",
      "Site: *#{inspection_request.site_name}*",
      "No of cranes: *#{inspection_request.cranes.size}*",
      "Company: *#{inspection_request.company_name}*",
      "Reference: *#{inspection_request.reference_code}*"
    ]

    lines << "-----------------"
    lines << "Status: *#{inspection_request.status.to_s.humanize}*"

    if inspection_request.scheduled_on.present?
      schedule = format_date(inspection_request.scheduled_on)
      schedule += " (#{inspection_request.scheduled_period})" if inspection_request.scheduled_period.present?
      lines << "Schedule: *#{schedule}*"
    end

    if inspection_request.fsp.present?
      lines << "Inspector: *#{inspection_request.inspector_label}*"
      lines << "Contact Number: *#{inspection_request.fsp.full_contact_number}*"
    end

    if inspection_request.share_token.present?
      lines << "-----------------"
      lines << "You may track the job status at this public link:"
      lines << public_status_url(inspection_request.share_token)
    end

    lines.join("\n")
  end

  # Small inline WhatsApp glyph to mark a phone number as chat-capable.
  def whatsapp_icon(css_class: "whatsapp-icon")
    content_tag :svg, class: css_class, viewBox: "0 0 32 32", fill: "currentColor", aria: { hidden: "true" } do
      content_tag :path, "", d: "M16.004 3C9.377 3 4 8.373 4 15c0 2.34.67 4.523 1.83 6.37L4 29l7.86-1.79A11.94 11.94 0 0 0 16.004 27C22.63 27 28 21.627 28 15S22.63 3 16.004 3Zm6.98 16.86c-.297.836-1.47 1.53-2.41 1.73-.64.135-1.475.244-4.287-.92-3.598-1.49-5.914-5.14-6.096-5.38-.176-.24-1.464-1.95-1.464-3.72 0-1.77.93-2.64 1.26-3 .33-.36.72-.45.96-.45.24 0 .48.003.69.014.222.012.52-.084.812.62.297.72 1.01 2.49 1.098 2.67.088.18.147.39.03.63-.117.24-.176.39-.35.6-.176.21-.37.47-.53.63-.176.176-.36.367-.155.72.207.354.918 1.51 1.97 2.446 1.353 1.207 2.494 1.582 2.848 1.758.354.176.56.147.766-.088.207-.234.882-1.03 1.118-1.383.235-.354.47-.294.793-.176.324.117 2.06.97 2.414 1.146.354.176.588.264.676.412.088.147.088.85-.21 1.686Z" end
  end

  def status_badge(status)
    css = case status.to_s
    when "pending" then "badge-pending"
    when "accepted" then "badge-accepted"
    when "scheduled" then "badge-scheduled"
    when "completed" then "badge-completed"
    when "rejected" then "badge-rejected"
    else "badge bg-stone-100 text-stone-700"
    end

    content_tag(:span, status.to_s.humanize, class: css)
  end

  def timeline_marker_classes(event)
    if event[:failed]
      "bg-red-100 text-red-700"
    elsif event[:done]
      "bg-green-600 text-white"
    else
      "bg-stone-200 text-stone-500"
    end
  end

  def timeline_marker_content(event, index)
    if event[:failed]
      "✕"
    elsif event[:done]
      "✓"
    else
      (index + 1).to_s
    end
  end

  def format_datetime(value)
    return "—" if value.blank?

    value.in_time_zone.strftime("%-d %b, %y · %-l:%M %p")
  end

  def format_date(value)
    return "—" if value.blank?

    value.in_time_zone.to_date.strftime("%-d %b, %y")
  end

  # Jobs list: same calendar day → time; otherwise → date (e.g. 25 Jul, 26).
  def format_list_timestamp(value)
    return "—" if value.blank?

    time = value.in_time_zone
    if time.to_date == Time.zone.today
      time.strftime("%-l:%M %p")
    else
      time.strftime("%-d %b, %y")
    end
  end

  # Sticky schedule dock summary for accepted jobs.
  def schedule_summary_label(inspection_request)
    parts = []
    if inspection_request.scheduled_on.present?
      parts << inspection_request.scheduled_on.strftime("%-d %b, %y")
    end
    parts << inspection_request.scheduled_period if inspection_request.scheduled_period.present?
    label = inspection_request.inspector_label
    parts << label if label.present?
    parts.presence&.join(" · ") || "Set schedule"
  end
end
