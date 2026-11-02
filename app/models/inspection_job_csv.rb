require "csv"

# One row per job for the dashboard jobs-index download.
class InspectionJobCsv
  HEADERS = [
    "Reference",
    "Status",
    "Scheduled date",
    "Period",
    "Site",
    "Company",
    "Requestor",
    "Requestor contact",
    "Email",
    "FSP",
    "Cranes",
    "Point of contact",
    "POC contact",
    "Site note",
    "Map",
    "Abort reason"
  ].freeze

  def initialize(jobs)
    @jobs = jobs
  end

  def to_s
    "\uFEFF" + CSV.generate do |csv|
      csv << HEADERS
      @jobs.each { |job| csv << row(job) }
    end
  end

  private

  def row(job)
    [
      job.reference_code,
      job.status.to_s.humanize,
      job.scheduled_on&.iso8601,
      job.scheduled_period,
      job.site_name,
      job.company_name,
      job.requestor_name,
      job.full_contact_number,
      job.email,
      job.fsp&.display_name.presence || "Unassigned",
      crane_summary(job),
      job.poc_name,
      job.point_of_contact? ? job.full_poc_contact_number : nil,
      job.site_note,
      job.map_url,
      job.aborted? ? job.abort_reason : nil
    ].map { |value| csv_safe(value) }
  end

  def crane_summary(job)
    job.cranes.map { |crane|
      "#{crane.crane_type_label} · #{crane.lm_number} · #{crane.rope_diameter_mm}"
    }.join("; ")
  end

  # Keep Excel from treating a site name or reason as a formula.
  # Phone numbers stay as +65 … so the file stays usable.
  def csv_safe(value)
    text = value.to_s
    return text if text.blank?
    return text if text.match?(/\A\+\d[\d\s\-]*\z/)
    return text unless text.match?(/\A[=+\-@\t\r]/)

    "'#{text}"
  end
end
