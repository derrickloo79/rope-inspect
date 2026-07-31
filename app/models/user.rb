class User < ApplicationRecord
  # Internal staff only — registration is disabled in routes/Devise config.
  # Admins are created/edited by other admins under Dashboard → Admins.
  devise :database_authenticatable,
         :recoverable,
         :rememberable,
         :validatable

  # Reuse FSP dial-code list for WhatsApp-ready numbers.
  COUNTRY_CODES = Fsp::COUNTRY_CODES
  DEFAULT_COUNTRY_CODE = Fsp::DEFAULT_COUNTRY_CODE

  validates :name, :contact_number, :country_code, presence: true
  validates :country_code, inclusion: { in: COUNTRY_CODES.map(&:last) }
  validates :contact_number, format: {
    with: /\A[0-9][0-9\s\-]{5,18}\z/,
    message: "should be digits only (spaces or dashes allowed)"
  }

  before_validation :normalize_contact_number
  before_validation :default_country_code

  scope :ordered, -> { order(:name, :email) }

  def display_name
    name.presence || email
  end

  def full_contact_number
    [ country_code, contact_number ].compact_blank.join(" ")
  end

  def whatsapp_number
    national = contact_number.to_s.gsub(/\D/, "").sub(/\A0+/, "")
    "#{country_code.to_s.gsub(/\D/, "")}#{national}"
  end

  private

  def default_country_code
    self.country_code = DEFAULT_COUNTRY_CODE if country_code.blank?
  end

  def normalize_contact_number
    return if contact_number.blank?

    self.contact_number = contact_number.to_s.strip.gsub(/[^\d\s\-]/, "")
  end
end
