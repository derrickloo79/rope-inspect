module ApplicationHelper
  def status_badge(status)
    css = case status.to_s
          when "pending" then "badge-pending"
          when "accepted" then "badge-accepted"
          when "scheduled" then "badge-scheduled"
          when "completed" then "badge-completed"
          else "badge bg-stone-100 text-stone-700"
          end

    content_tag(:span, status.to_s.humanize, class: css)
  end

  def format_datetime(value)
    return "—" if value.blank?

    value.strftime("%-d %b %Y · %-l:%M %p")
  end

  def format_date(value)
    return "—" if value.blank?

    value.strftime("%-d %b %Y")
  end
end
