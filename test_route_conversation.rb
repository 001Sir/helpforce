#!/usr/bin/env ruby
# Test routing a conversation using HelpForce API

require 'net/http'
require 'json'
require 'uri'

API_TOKEN = '81ouad8exqFUufXqhU5reg6c'
BASE_URL = 'http://localhost:3000/api/v1/accounts/1/integrations'

def make_request(path, method = :get, body = nil)
  uri = URI("#{BASE_URL}#{path}")
  
  case method
  when :get
    request = Net::HTTP::Get.new(uri)
  when :post
    request = Net::HTTP::Post.new(uri)
    request.body = body.to_json if body
  end
  
  request['Accept'] = 'application/json'
  request['Content-Type'] = 'application/json'
  request['api_access_token'] = API_TOKEN
  
  response = Net::HTTP.start(uri.hostname, uri.port) do |http|
    http.request(request)
  end
  
  JSON.parse(response.body)
end

# Get open conversations
puts "Finding open conversations..."
uri = URI("http://localhost:3000/api/v1/accounts/1/conversations")
request = Net::HTTP::Get.new(uri)
request['api_access_token'] = API_TOKEN
request['Accept'] = 'application/json'

conversations_response = Net::HTTP.start(uri.hostname, uri.port) do |http|
  http.request(request)
end

conversations = JSON.parse(conversations_response.body)

# Extract conversations from nested structure
if conversations['data'] && conversations['data']['payload']
  all_conversations = conversations['data']['payload']
elsif conversations['payload']
  all_conversations = conversations['payload']
else
  all_conversations = []
end

# Filter to find our test conversations (unassigned ones)
open_conversations = all_conversations.select do |conv|
  conv['assignee_last_seen_at'].nil? || conv['meta']['assignee'].nil?
end

# If no unassigned, use any open conversation
if open_conversations.empty?
  open_conversations = all_conversations.select { |c| c['status'] == 'open' }
end

if open_conversations.empty?
  puts "No suitable conversations found!"
  exit
end

puts "Found #{open_conversations.length} suitable conversations"

# Find a test conversation (preferably one we created)
test_emails = ['john.tech@example.com', 'sarah.billing@example.com', 'mike.new@example.com', 
               'emma.urgent@example.com', 'carlos.es@example.com']

conversation = open_conversations.find do |conv|
  test_emails.include?(conv['meta']['sender']['email']) if conv['meta'] && conv['meta']['sender']
end || open_conversations.first
puts "\nRouting conversation ##{conversation['display_id']} (ID: #{conversation['id']})"
puts "Contact: #{conversation['meta']['sender']['name']}"

# Call the routing API
route_response = make_request(
  "/helpforce_routing/conversations/#{conversation['id']}/route",
  :post
)

puts "\nRouting Response:"
puts JSON.pretty_generate(route_response)

# Check if routing was successful
if route_response['success']
  puts "\n✅ Conversation routed successfully!"
  puts "Assigned to: #{route_response['data']['assigned_agent']['name']}"
  puts "Confidence: #{route_response['data']['confidence']}%"
  puts "Reasons: #{route_response['data']['reasons'].join(', ')}"
else
  puts "\n❌ Routing failed: #{route_response['message']}"
end

# Get analytics again
puts "\nChecking analytics after routing..."
analytics = make_request('/helpforce_routing/analytics')
puts "Total assignments: #{analytics['data']['routing_overview']['total_assignments']}"
puts "Auto assignments: #{analytics['data']['routing_overview']['auto_assignments']}"