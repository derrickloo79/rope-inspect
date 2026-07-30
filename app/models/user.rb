class User < ApplicationRecord
  # Internal staff only — registration is disabled in routes/Devise config.
  # Admins are created/edited by other admins under Dashboard → Admins.
  devise :database_authenticatable,
         :recoverable,
         :rememberable,
         :validatable

  validates :name, presence: true

  scope :ordered, -> { order(:name, :email) }

  def display_name
    name.presence || email
  end
end
