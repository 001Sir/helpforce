#!/usr/bin/env ruby
# Test script for HelpForce routing API

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
  
  if response.content_type == 'application/json'
    JSON.parse(response.body)
  else
    puts "Error: Received HTML response instead of JSON"
    puts "Status: #{response.code}"
    puts "First 200 chars of response:"
    puts response.body[0..200]
    nil
  end
end

# Test HelpForce APIs
puts "Testing HelpForce APIs..."
puts "=" * 50

# Test AI Service
puts "\n1. Testing AI Service..."
ai_status = make_request('/helpforce_ai')
if ai_status
  puts "✅ AI Service is working!"
  puts "   Default provider: #{ai_status['default_provider']}"
  puts "   Providers configured:"
  ai_status['providers'].each do |provider, info|
    puts "   - #{provider}: #{info['configured'] ? '✅ Configured' : '❌ Not configured'}"
  end
end

# Test Marketplace
puts "\n2. Testing Marketplace..."
marketplace = make_request('/helpforce_marketplace')
if marketplace
  puts "✅ Marketplace is working!"
  puts "   Total agents: #{marketplace['total_available']}"
  puts "   Installed: #{marketplace['installed_count']}"
end

# Test Routing - Analytics
puts "\n3. Testing Routing Analytics..."
analytics = make_request('/helpforce_routing/analytics')
if analytics
  puts "✅ Routing Analytics is working!"
  puts "   Data: #{analytics}"
else
  puts "❌ Routing Analytics failed"
end

# Test Routing - Needs Attention
puts "\n4. Testing Routing Needs Attention..."
needs_attention = make_request('/helpforce_routing/needs_attention')
if needs_attention
  puts "✅ Routing Needs Attention is working!"
  puts "   Data: #{needs_attention}"
else
  puts "❌ Routing Needs Attention failed"
end

# Test Routing - Agent Workload
puts "\n5. Testing Routing Agent Workload..."
workload = make_request('/helpforce_routing/agent_workload')
if workload
  puts "✅ Routing Agent Workload is working!"
  puts "   Data: #{workload}"
else
  puts "❌ Routing Agent Workload failed"
end

puts "\n" + "=" * 50
puts "Testing complete!"