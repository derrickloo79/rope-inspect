class InspectionRequest < ApplicationRecord
  STATUSES = %w[pending accepted scheduled completed rejected].freeze

  has_many :cranes, -> { order(:position, :id) }, dependent: :destroy, inverse_of: :inspection_request
  accepts_nested_attributes_for :cranes, allow_destroy: true, reject_if: :all_blank

  validates :company_name, :requestor_name, :contact_number, :site_name, presence: true
  validates :status, inclusion: { in: STATUSES }
  validates :share_token, uniqueness: true, allow_nil: true
  validate :must_have_at_least_one_crane

  before_validation :set_default_status, on: :create
  before_validation :assign_crane_positions

  scope :pending, -> { where(status: "pending") }
  scope :accepted, -> { where(status: "accepted") }
  scope :scheduled, -> { where(status: "scheduled") }
  scope :completed, -> { where(status: "completed") }
  scope :rejected, -> { where(status: "rejected") }
  scope :recent_first, -> { order(created_at: :desc) }

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

  def schedule!(on:, at: nil, inspector: nil)
    return false unless accepted? || scheduled?

    update!(
      status: "scheduled",
      scheduled_on: on,
      scheduled_time: at,
      assigned_inspector: inspector.presence || assigned_inspector,
      scheduled_at: Time.current
    )
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

  private

  def set_default_status
    self.status ||= "pending"
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

    parts = [ scheduled_on.strftime("%-d %b %Y") ]
    parts << scheduled_period if scheduled_period.present?
    parts << "· #{assigned_inspector}" if assigned_inspector.present?
    parts.join(" ")
  end
end
