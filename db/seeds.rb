# Staff account for the internal dashboard
User.find_or_create_by!(email: "staff@ropeinspect.local") do |user|
  user.password = "password123"
  user.password_confirmation = "password123"
end

puts "Seeded staff user: staff@ropeinspect.local / password123"
