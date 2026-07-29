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

  belongs_to :inspection_request, inverse_of: :cranes

  validates :crane_type, presence: true, inclusion: { in: CRANE_TYPES.keys }
  validates :lm_number, presence: true
  validates :rope_diameter_mm, presence: true

  def crane_type_label
    CRANE_TYPES[crane_type] || crane_type.to_s.humanize
  end
end
