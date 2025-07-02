#!/usr/bin/env ruby
# Simple test to route a specific conversation

require 'net/http'
require 'json'
require 'uri'

API_TOKEN = '81ouad8exqFUufXqhU5reg6c'
BASE_URL = 'http://localhost:3000/api/v1/accounts/1/integrations'

# Get conversation ID from command line or use default
conversation_id = ARGV[0] || '14' # One of our test conversations

puts "Testing routing for conversation ID: #{conversation_id}"
puts "=" * 50

# Test the routing endpoint
uri = URI("#{BASE_URL}/helpforce_routing/conversations/#{conversation_id}/route")
request = Net::HTTP::Post.new(uri)
request['Accept'] = 'application/json'
request['Content-Type'] = 'application/json'
request['api_access_token'] = API_TOKEN

response = Net::HTTP.start(uri.hostname, uri.port) do |http|
  http.request(request)
end

puts "\nResponse Status: #{response.code}"
puts "Response Headers: #{response.to_hash.inspect}"
puts "\nResponse Body:"

begin
  result = JSON.parse(response.body)
  puts JSON.pretty_generate(result)
  
  if result['success']
    puts "\n✅ SUCCESS! Conversation routed to: #{result['data']['assigned_agent']['name']}"
  else
    puts "\n❌ FAILED: #{result['message']}"
  end
rescue JSON::ParserError => e
  puts "Error parsing JSON: #{e.message}"
  puts "Raw response: #{response.body[0..500]}..."
end