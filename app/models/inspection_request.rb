class InspectionRequest < ApplicationRecord
  STATUSES = %w[pending accepted scheduled completed rejected].freeze

  belongs_to :fsp, optional: true, inverse_of: :inspection_requests
  has_many :cranes, -> { order(:position, :id) }, dependent: :destroy, inverse_of: :inspection_request
  accepts_nested_attributes_for :cranes, allow_destroy: true, reject_if: :all_blank

  # Same dial codes as FSP / admin (WhatsApp-ready).
  COUNTRY_CODES = Fsp::COUNTRY_CODES
  DEFAULT_COUNTRY_CODE = Fsp::DEFAULT_COUNTRY_CODE

  validates :company_name, :requestor_name, :contact_number, :country_code, :site_name, presence: true
  validates :country_code, inclusion: { in: COUNTRY_CODES.map(&:last) }
  validates :contact_number, format: {
    with: /\A[0-9][0-9\s\-]{5,18}\z/,
    message: "should be digits only (spaces or dashes allowed)"
  }
  validates :status, inclusion: { in: STATUSES }
  validates :share_token, uniqueness: true, allow_nil: true
  MAP_URL_FORMAT = %r{\Ahttps?://[^\s]+\z}i

  validates :map_url, format: {
    with: MAP_URL_FORMAT,
    message: "must be a full URL starting with http:// or https://"
  }, allow_blank: true
  validates :poc_country_code, inclusion: { in: COUNTRY_CODES.map(&:last) }, allow_blank: true
  validates :poc_contact_number, format: {
    with: /\A[0-9][0-9\s\-]{5,18}\z/,
    message: "should be digits only (spaces or dashes allowed)"
  }, allow_blank: true
  validate :must_have_at_least_one_crane
  validate :poc_name_and_contact_together

  before_validation :set_default_status, on: :create
  before_validation :default_country_code
  before_validation :normalize_contact_number
  before_validation :normalize_map_url
  before_validation :normalize_site_note
  before_validation :normalize_poc_fields
  before_validation :assign_crane_positions
  before_validation :sync_assigned_inspector_from_fsp

  scope :pending, -> { where(status: "pending") }
  scope :accepted, -> { where(status: "accepted") }
  scope :scheduled, -> { where(status: "scheduled") }
  scope :completed, -> { where(status: "completed") }
  scope :rejected, -> { where(status: "rejected") }
  scope :recent_first, -> { order(created_at: :desc) }
  scope :for_fsp, ->(fsp) { where(fsp_id: fsp.id) }
  scope :upcoming_within, ->(days = 7) {
    scheduled
      .where.not(scheduled_on: nil)
      .where(scheduled_on: Date.current..(Date.current + (days - 1).days))
      .order(:scheduled_on, :scheduled_time, :company_name)
  }

  scope :in_week, ->(week_start) {
    start = week_start.to_date
    scheduled
      .where(scheduled_on: start..(start + 6.days))
      .order(:scheduled_on, :scheduled_time, :company_name)
  }

  def pending?
    status == "pending"
  end

  def accepted?
    status == "accepted"
  end

  def scheduled?
    status == "scheduled"
  end

  def completed?
    status == "completed"
  end

  def rejected?
    status == "rejected"
  end

  def public_status?
    share_token.present? && !pending? && !rejected?
  end

  # Simple state machine transitions
  def accept!
    return false unless pending?

    transaction do
      update!(
        status: "accepted",
        accepted_at: Time.current,
        share_token: share_token.presence || generate_share_token
      )
    end
  end

  def reject!
    return false unless pending?

    update!(status: "rejected", rejected_at: Time.current)
  end

  def reopen!
    return false unless rejected?

    update!(status: "pending", rejected_at: nil)
  end

  # fsp: Fsp record, or nil to leave unassigned.
  def schedule!(on:, at: nil, fsp: nil)
    return false unless accepted? || scheduled?

    update!(
      status: "scheduled",
      scheduled_on: on,
      scheduled_time: at,
      scheduled_at: Time.current,
      fsp: fsp,
      assigned_inspector: fsp&.display_name
    )
  end

  def inspector_label
    fsp&.display_name.presence || assigned_inspector.presence
  end

  # Sort key for day lists / planner chips: AM before PM, then FSP number, then company.
  def schedule_sort_key
    period_rank =
      case scheduled_period
      when "AM" then 0
      when "PM" then 1
      else 2
      end

    fsp_rank = fsp&.sequence_number || Float::INFINITY
    [ period_rank, fsp_rank, company_name.to_s.downcase ]
  end

  def complete!
    return false unless scheduled?

    update!(status: "completed", completed_at: Time.current)
  end

  def status_timeline
    events = [
      {
        key: "submitted",
        label: "Request submitted",
        at: created_at,
        done: true
      }
    ]

    if rejected?
      events << {
        key: "rejected",
        label: "Rejected",
        at: rejected_at,
        done: true,
        failed: true
      }
      return events
    end

    events + [
      {
        key: "accepted",
        label: "Accepted",
        at: accepted_at,
        done: accepted_at.present?
      },
      {
        key: "scheduled",
        label: "Scheduled",
        at: scheduled_at,
        done: scheduled_at.present?,
        detail: schedule_detail
      },
      {
        key: "completed",
        label: "Completed",
        at: completed_at,
        done: completed_at.present?
      }
    ]
  end

  def reference_code
    "RI-#{id.to_s.rjust(5, '0')}"
  end

  # AM / PM derived from the stored time-of-day (AM before noon, PM otherwise).
  def scheduled_period
    return nil if scheduled_time.blank?

    scheduled_time.hour < 12 ? "AM" : "PM"
  end

  def full_contact_number
    [ country_code, contact_number ].compact_blank.join(" ")
  end

  def whatsapp_number
    national = contact_number.to_s.gsub(/\D/, "").sub(/\A0+/, "")
    "#{country_code.to_s.gsub(/\D/, "")}#{national}"
  end

  def site_access?
    map_url.present? || site_note.present?
  end

  def point_of_contact?
    poc_name.present? && poc_contact_number.present?
  end

  def full_poc_contact_number
    [ poc_country_code.presence || DEFAULT_COUNTRY_CODE, poc_contact_number ].compact_blank.join(" ")
  end

  def poc_whatsapp_number
    return nil if poc_contact_number.blank?

    national = poc_contact_number.to_s.gsub(/\D/, "").sub(/\A0+/, "")
    code = (poc_country_code.presence || DEFAULT_COUNTRY_CODE).to_s.gsub(/\D/, "")
    "#{code}#{national}"
  end

  # Only return http(s) URLs for use in link hrefs (avoids javascript: etc.).
  def safe_map_url
    url = map_url.to_s.strip
    return nil if url.blank?
    return nil unless url.match?(MAP_URL_FORMAT)

    uri = URI.parse(url)
    return url if uri.is_a?(URI::HTTP)

    nil
  rescue URI::InvalidURIError
    nil
  end

  private

  def set_default_status
    self.status ||= "pending"
  end

  def default_country_code
    self.country_code = DEFAULT_COUNTRY_CODE if country_code.blank?
  end

  def normalize_contact_number
    return if contact_number.blank?

    self.contact_number = contact_number.to_s.strip.gsub(/[^\d\s\-]/, "")
  end

  def normalize_map_url
    self.map_url = map_url.to_s.strip.presence
  end

  def normalize_site_note
    self.site_note = site_note.to_s.strip.presence
  end

  def normalize_poc_fields
    self.poc_name = poc_name.to_s.strip.presence
    self.poc_contact_number = poc_contact_number.to_s.strip.gsub(/[^\d\s\-]/, "").presence
    self.poc_country_code = poc_country_code.to_s.strip.presence
    self.poc_country_code = DEFAULT_COUNTRY_CODE if poc_contact_number.present? && poc_country_code.blank?
  end

  def poc_name_and_contact_together
    name_set = poc_name.present?
    number_set = poc_contact_number.present?
    return if name_set == number_set

    errors.add(:poc_name, "can't be blank when contact number is set") if number_set && !name_set
    errors.add(:poc_contact_number, "can't be blank when name is set") if name_set && !number_set
  end

  def assign_crane_positions
    cranes.each_with_index do |crane, index|
      crane.position = index unless crane.marked_for_destruction?
    end
  end

  def must_have_at_least_one_crane
    active = cranes.reject(&:marked_for_destruction?)
    errors.add(:base, "Add at least one crane to inspect.") if active.empty?
  end

  def generate_share_token
    loop do
      token = SecureRandom.urlsafe_base64(16)
      break token unless self.class.exists?(share_token: token)
    end
  end

  def schedule_detail
    return nil unless scheduled_on.present?

    parts = [ scheduled_on.strftime("%-d %b, %y") ]
    parts << scheduled_period if scheduled_period.present?
    label = inspector_label
    parts << "· #{label}" if label.present?
    parts.join(" ")
  end

  def sync_assigned_inspector_from_fsp
    return if fsp.blank?

    self.assigned_inspector = fsp.display_name
  end
end
