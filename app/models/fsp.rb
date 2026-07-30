class Fsp < ApplicationRecord
  # Login so inspectors can view their assigned jobs.
  devise :database_authenticatable,
         :recoverable,
         :rememberable,
         :validatable

  # Distinct palette for chips / planner differentiation.
  COLOR_PALETTE = %w[
    #ef4444
    #f97316
    #eab308
    #84cc16
    #22c55e
    #14b8a6
    #06b6d4
    #0ea5e9
    #3b82f6
    #6366f1
    #8b5cf6
    #a855f7
    #d946ef
    #ec4899
    #f43f5e
    #78716c
    #0f766e
    #b45309
    #1d4ed8
    #7c3aed
  ].freeze

  # Dial codes for contact / WhatsApp (label, E.164 prefix). SG first as app default.
  COUNTRY_CODES = [
    [ "Singapore (+65)", "+65" ],
    [ "Malaysia (+60)", "+60" ],
    [ "Indonesia (+62)", "+62" ],
    [ "Thailand (+66)", "+66" ],
    [ "Philippines (+63)", "+63" ],
    [ "Vietnam (+84)", "+84" ],
    [ "India (+91)", "+91" ],
    [ "China (+86)", "+86" ],
    [ "Hong Kong (+852)", "+852" ],
    [ "Taiwan (+886)", "+886" ],
    [ "Japan (+81)", "+81" ],
    [ "South Korea (+82)", "+82" ],
    [ "Australia (+61)", "+61" ],
    [ "New Zealand (+64)", "+64" ],
    [ "United Kingdom (+44)", "+44" ],
    [ "United States / Canada (+1)", "+1" ],
    [ "United Arab Emirates (+971)", "+971" ],
    [ "Saudi Arabia (+966)", "+966" ],
    [ "Germany (+49)", "+49" ],
    [ "France (+33)", "+33" ],
    [ "Netherlands (+31)", "+31" ],
    [ "Brunei (+673)", "+673" ],
    [ "Bangladesh (+880)", "+880" ],
    [ "Pakistan (+92)", "+92" ],
    [ "Sri Lanka (+94)", "+94" ],
    [ "Myanmar (+95)", "+95" ],
    [ "Cambodia (+855)", "+855" ],
    [ "Laos (+856)", "+856" ]
  ].freeze

  DEFAULT_COUNTRY_CODE = "+65"

  has_many :inspection_requests, dependent: :nullify, inverse_of: :fsp

  validates :full_name, :contact_number, :country_code, :date_joined, presence: true
  validates :country_code, inclusion: { in: COUNTRY_CODES.map(&:last) }
  validates :contact_number, format: {
    with: /\A[0-9][0-9\s\-]{5,18}\z/,
    message: "should be digits only (spaces or dashes allowed)"
  }
  validates :sequence_number, :fsp_number, :color, presence: true, uniqueness: true
  validates :color, format: { with: /\A#[0-9a-fA-F]{6}\z/, message: "must be a hex color like #3b82f6" }

  before_validation :assign_identity, on: :create
  before_validation :normalize_contact_number

  scope :ordered, -> { order(:sequence_number) }

  def display_name
    "#{fsp_number} · #{full_name}"
  end

  # Human-readable: "+65 9123 4567"
  def full_contact_number
    [ country_code, contact_number ].compact_blank.join(" ")
  end

  # Digits only for WhatsApp Cloud API (e.g. "6591234567")
  def whatsapp_number
    national = contact_number.to_s.gsub(/\D/, "").sub(/\A0+/, "")
    "#{country_code.to_s.gsub(/\D/, "")}#{national}"
  end

  # Jobs this FSP can see in the portal (assigned only).
  def assigned_jobs
    inspection_requests.includes(:cranes).recent_first
  end

  private

  def assign_identity
    self.country_code = DEFAULT_COUNTRY_CODE if country_code.blank?
    assign_sequence_and_number if sequence_number.blank? || fsp_number.blank?
    assign_unique_color if color.blank?
  end

  def normalize_contact_number
    return if contact_number.blank?

    # Keep digits, spaces, and dashes for display; strip other junk.
    self.contact_number = contact_number.to_s.strip.gsub(/[^\d\s\-]/, "")
  end

  def assign_sequence_and_number
    next_n = (self.class.maximum(:sequence_number) || 0) + 1
    self.sequence_number = next_n
    self.fsp_number = "FSP#{next_n}"
  end

  def assign_unique_color
    used = self.class.where.not(id: id).pluck(:color)
    available = COLOR_PALETTE - used
    self.color =
      if available.any?
        available.first
      else
        # Fallback when palette is exhausted: stable HSL from sequence.
        hue = ((sequence_number || 1) * 47) % 360
        hsl_to_hex(hue, 65, 48)
      end
  end

  def hsl_to_hex(h, s, l)
    s /= 100.0
    l /= 100.0
    c = (1 - (2 * l - 1).abs) * s
    x = c * (1 - ((h / 60.0) % 2 - 1).abs)
    m = l - c / 2
    r, g, b =
      case h
      when 0...60 then [ c, x, 0 ]
      when 60...120 then [ x, c, 0 ]
      when 120...180 then [ 0, c, x ]
      when 180...240 then [ 0, x, c ]
      when 240...300 then [ x, 0, c ]
      else [ c, 0, x ]
      end
    format("#%02x%02x%02x", ((r + m) * 255).round, ((g + m) * 255).round, ((b + m) * 255).round)
  end
end
