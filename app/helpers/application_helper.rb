module ApplicationHelper
  def nav_link_active?(section)
    case section
    when :dashboard
      controller_path == "dashboard/home"
    when :jobs
      controller_path == "dashboard/inspection_requests"
    when :public_form
      controller_path == "inspection_requests" || controller_path == "status"
    else
      false
    end
  end

  def site_header_link_class(section)
    classes = [ "site-header-link" ]
    classes << "is-active" if nav_link_active?(section)
    classes.join(" ")
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
end
