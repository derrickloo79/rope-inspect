class Crane < ApplicationRecord
  CRANE_TYPES = {
    "crawler_crane" => "Crawler crane",
    "mobile_crane" => "Mobile crane",
    "tower_crane" => "Tower crane",
    "fly_jib_crane" => "Fly jib crane",
    "gantry_crane" => "Gantry crane",
    "ropeway" => "Ropeway",
    "zip_line" => "Zip line",
    "boring_rig" => "Boring rig",
    "others" => "Others"
  }.freeze

  CERT_CONTENT_TYPES = %w[application/pdf image/jpeg image/png].freeze
  CERT_EXTENSIONS = %w[pdf jpg jpeg png].freeze
  CERT_MAX_BYTES = 15.megabytes

  belongs_to :inspection_request, inverse_of: :cranes

  # Optional certificates (requestor or admin). LM = single file; Mill = many.
  has_one_attached :lm_certificate
  has_many_attached :mill_certificates

  validates :crane_type, presence: true, inclusion: { in: CRANE_TYPES.keys }
  validates :lm_number, presence: true
  validates :rope_diameter_mm, presence: true
  validate :lm_certificate_must_be_acceptable
  validate :mill_certificates_must_be_acceptable

  def crane_type_label
    CRANE_TYPES[crane_type] || crane_type.to_s.humanize
  end

  def certificates_complete?
    lm_certificate.attached? && mill_certificates.attached?
  end

  private

  def lm_certificate_must_be_acceptable
    return unless lm_certificate.attached?

    blob = lm_certificate.blob
    unless CERT_CONTENT_TYPES.include?(blob.content_type)
      errors.add(:lm_certificate, "must be a PDF, JPG, or PNG")
    end
    if blob.byte_size > CERT_MAX_BYTES
      errors.add(:lm_certificate, "must be smaller than 15 MB")
    end
  end

  def mill_certificates_must_be_acceptable
    return unless mill_certificates.attached?

    mill_certificates.each do |file|
      blob = file.blob
      unless CERT_CONTENT_TYPES.include?(blob.content_type)
        errors.add(:mill_certificates, "must be PDF, JPG, or PNG (#{blob.filename} is not allowed)")
        break
      end
      if blob.byte_size > CERT_MAX_BYTES
        errors.add(:mill_certificates, "#{blob.filename} must be smaller than 15 MB")
        break
      end
    end
  end
end
