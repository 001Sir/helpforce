Rails.application.reload_routes!
captain_routes = Rails.application.routes.routes.select { |r| r.path.spec.to_s.include?('captain') }
puts "Captain routes found: #{captain_routes.count}"

if captain_routes.any?
  puts 'Sample Captain routes:'
  captain_routes.first(5).each do |route|
    puts "  #{route.verb.ljust(8)} #{route.path.spec}"
  end

  # Test route recognition
  begin
    recognized = Rails.application.routes.recognize_path('/api/v1/accounts/1/captain/assistants', method: :get)
    puts "Route recognition successful: #{recognized}"
  rescue StandardError => e
    puts "Route recognition error: #{e.message}"
  end
else
  puts 'No Captain routes found'
end