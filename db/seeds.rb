# Create default admin user
admin = User.find_or_create_by!(email_address: "admin@localtask.dev") do |u|
  u.name = "Admin"
  u.password = "password"
  u.password_confirmation = "password"
  u.role = :admin
end

puts "Admin user: admin@localtask.dev / password"

# Create a sample project (default statuses created via after_create callback)
project = Project.find_or_create_by!(prefix: "LT") do |p|
  p.name = "LocalTask Development"
  p.description = "Building the LocalTask Kanban system"
  p.color = "#6366f1"
  p.user = admin
end

puts "Project created: #{project.name} (#{project.prefix})"
puts "Statuses: #{project.task_statuses.ordered.pluck(:name).join(', ')}"

# Create a sample API token for testing
if admin.api_tokens.empty?
  token = admin.api_tokens.create!(name: "Development Token")
  puts "\nAPI Token (save this!): #{token.raw_token}"
end
