# Staff account for the internal dashboard
User.find_or_create_by!(email: "staff@ropeinspect.local") do |user|
  user.name = "Staff"
  user.password = "password123"
  user.password_confirmation = "password123"
end

# Ensure name is set if the user already existed without one
staff = User.find_by(email: "staff@ropeinspect.local")
if staff && staff.name.blank?
  staff.update!(name: "Staff")
end

puts "Seeded staff user: staff@ropeinspect.local / password123"
