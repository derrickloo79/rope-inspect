class User < ApplicationRecord
  # Internal staff only — registration is disabled in routes/Devise config.
  devise :database_authenticatable,
         :recoverable,
         :rememberable,
         :validatable
end
