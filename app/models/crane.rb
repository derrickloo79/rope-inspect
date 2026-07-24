class Crane < ApplicationRecord
  CRANE_TYPES = {
    "tower_crane" => "Tower crane",
    "mobile_crane" => "Mobile crane",
    "crawler_crane" => "Crawler crane",
    "overhead_gantry" => "Overhead / gantry",
    "rough_terrain" => "Rough terrain",
    "deck_crane" => "Deck crane",
    "portal_slewing" => "Portal slewing"
  }.freeze

  belongs_to :inspection_request, inverse_of: :cranes

  validates :crane_type, presence: true, inclusion: { in: CRANE_TYPES.keys }
  validates :lm_number, presence: true
  validates :rope_diameter_mm, presence: true

  def crane_type_label
    CRANE_TYPES[crane_type] || crane_type.to_s.humanize
  end
end
