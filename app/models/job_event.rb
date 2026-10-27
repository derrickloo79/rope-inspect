class JobEvent < ApplicationRecord
  ACTIONS = %w[
    accepted rejected scheduled rescheduled completed aborted on_hold cancelled
    poc_updated site_access_updated crane_remarks_updated crane_certificates_updated crane_details_updated
  ].freeze
  STATUS_MOVES = %w[accepted rejected scheduled completed aborted on_hold cancelled].freeze
  DETAIL_UPDATES = %w[
    poc_updated site_access_updated crane_remarks_updated crane_certificates_updated crane_details_updated
  ].freeze

  belongs_to :inspection_request
  belongs_to :user, optional: true

  validates :action, inclusion: { in: ACTIONS }
  validates :occurred_at, presence: true

  scope :chronological, -> { order(:occurred_at, :id) }

  def actor_name
    user&.display_name.presence
  end

  def status_move?
    STATUS_MOVES.include?(action)
  end

  def label
    {
      "accepted" => "Accepted",
      "rejected" => "Rejected",
      "scheduled" => "Scheduled",
      "rescheduled" => "Rescheduled",
      "completed" => "Completed",
      "aborted" => "Aborted",
      "on_hold" => "Put on hold",
      "cancelled" => "Cancelled",
      "poc_updated" => "Updated point of contact",
      "site_access_updated" => "Updated site access",
      "crane_remarks_updated" => "Updated crane remarks",
      "crane_certificates_updated" => "Updated crane certificates",
      "crane_details_updated" => "Updated crane details"
    }.fetch(action)
  end

  def detail
    case action
    when "scheduled"
      visit_phrase
    when "rescheduled"
      [ visit_phrase("previous_"), visit_phrase ].compact.join(" → ").presence
    when *DETAIL_UPDATES
      details["summary"].presence
    end
  end

  def reason
    return unless %w[on_hold aborted cancelled].include?(action)

    details["reason"].presence
  end

  private

  def visit_phrase(prefix = "")
    raw_date = details["#{prefix}scheduled_on"]
    return nil if raw_date.blank?

    date = Date.iso8601(raw_date).strftime("%-d %b, %y")
    phrase = [ date, details["#{prefix}period"].presence ].compact.join(" ")
    number = details["#{prefix}fsp_number"].presence
    "#{phrase} · #{number || "Unassigned"}"
  end
end
