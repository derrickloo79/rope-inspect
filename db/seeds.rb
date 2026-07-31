# Staff account for the internal dashboard
User.find_or_create_by!(email: "staff@ropeinspect.local") do |user|
  user.name = "Staff"
  user.country_code = User::DEFAULT_COUNTRY_CODE
  user.contact_number = "91234567"
  user.password = "password123"
  user.password_confirmation = "password123"
end

staff = User.find_by(email: "staff@ropeinspect.local")
if staff
  staff.name = "Staff" if staff.name.blank?
  staff.country_code = User::DEFAULT_COUNTRY_CODE if staff.country_code.blank?
  staff.contact_number = "91234567" if staff.contact_number.blank? || staff.contact_number == "00000000"
  staff.save! if staff.changed?
end

puts "Seeded staff user: staff@ropeinspect.local / password123"
