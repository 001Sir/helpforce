#!/usr/bin/env ruby
# Complete HelpForce Platform Demo

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
  
  JSON.parse(response.body) rescue response.body
end

puts "🚀 HelpForce Platform Demo"
puts "=" * 60
puts "\nHelpForce is an AI-enhanced customer support platform built on Chatwoot"
puts "It features multi-model AI support, smart routing, and an agent marketplace.\n"

# 1. Show AI Configuration Status
puts "\n1️⃣  AI Configuration Status"
puts "-" * 40
ai_status = make_request('/helpforce_ai')
puts "✅ Default Provider: #{ai_status['default_provider']}"
ai_status['providers'].each do |provider, info|
  status = info['configured'] ? '✅ Configured' : '❌ Not configured'
  puts "   #{provider}: #{status}"
end

# 2. Show Agent Marketplace
puts "\n\n2️⃣  AI Agent Marketplace"
puts "-" * 40
marketplace = make_request('/helpforce_marketplace')
puts "📦 Total Available Agents: #{marketplace['total_available']}"
puts "✅ Installed Agents: #{marketplace['installed_count']}"
puts "\nInstalled Agents:"
marketplace['agents'].select { |a| a['installed'] }.each do |agent|
  puts "   • #{agent['name']} (#{agent['category']}) - #{agent['description']}"
end

# 3. Demonstrate Smart Routing
puts "\n\n3️⃣  Smart Conversation Routing"
puts "-" * 40
puts "Testing routing for different conversation types...\n"

# Get a pending conversation
conversations_uri = URI("http://localhost:3000/api/v1/accounts/1/conversations?status=pending")
req = Net::HTTP::Get.new(conversations_uri)
req['api_access_token'] = API_TOKEN
req['Accept'] = 'application/json'

conv_response = Net::HTTP.start(conversations_uri.hostname, conversations_uri.port) do |http|
  http.request(req)
end

conversations = JSON.parse(conv_response.body)
pending_convs = conversations['data']['payload'] rescue []

if pending_convs.any?
  conv = pending_convs.first
  puts "📧 Routing conversation ##{conv['id']} from #{conv['meta']['sender']['name']}"
  
  # Route the conversation
  routing_result = make_request("/helpforce_routing/conversations/#{conv['id']}/route", :post)
  
  if routing_result['success']
    agent = routing_result['data']['assigned_agent']
    puts "✅ Routed to: #{agent['name']}"
    puts "   Confidence: #{routing_result['data']['confidence']}%"
    puts "   Reasons: #{routing_result['data']['reasons'].join(', ')}"
  else
    puts "❌ Routing failed: #{routing_result['message']}"
  end
else
  puts "ℹ️  No pending conversations to route"
end

# 4. Show AI Capabilities
puts "\n\n4️⃣  AI Text Processing Capabilities"
puts "-" * 40

# Sentiment Analysis
test_texts = [
  "This product is amazing! Best purchase ever!",
  "I'm having some issues with the login process",
  "TERRIBLE SERVICE! I want a refund NOW!"
]

puts "\n📊 Sentiment Analysis:"
test_texts.each do |text|
  result = make_request('/helpforce_ai/analyze_sentiment', :post, { text: text })
  puts "   \"#{text[0..50]}#{text.length > 50 ? '...' : ''}\""
  puts "   → #{result['sentiment']} (#{result['confidence']} confidence)\n"
end

# Text Rephrasing
puts "\n✏️  Professional Rephrasing:"
casual_text = "hey whats up, need help with my acct"
result = make_request('/helpforce_ai/rephrase_text', :post, { 
  text: casual_text, 
  style: 'professional' 
})
puts "   Original: \"#{casual_text}\""
puts "   Professional: \"#{result['content'] || 'Could not rephrase'}\""

# 5. Show Routing Analytics
puts "\n\n5️⃣  Routing Analytics & Metrics"
puts "-" * 40
analytics = make_request('/helpforce_routing/analytics')
overview = analytics['data']['routing_overview']
puts "📈 Routing Overview (Last 7 days):"
puts "   Total Assignments: #{overview['total_assignments']}"
puts "   Auto-routed: #{overview['auto_assignments']}"
puts "   Manual: #{overview['manual_assignments']}"
puts "   Average Confidence: #{overview['average_confidence']}%"

# 6. Agent Workload
puts "\n\n6️⃣  AI Agent Workload"
puts "-" * 40
workload = make_request('/helpforce_routing/agent_workload')
puts "👥 Agent Performance:"
workload['data']['agents'].each do |agent|
  puts "\n   #{agent['agent_name']} (#{agent['agent_category']})"
  puts "   - Active Conversations: #{agent['active_conversations']}"
  puts "   - Completed Today: #{agent['completed_today']}"
  puts "   - Avg Handling Time: #{agent['avg_handling_time']} min"
  puts "   - Satisfaction Score: #{agent['satisfaction_score']}/5"
end

# Summary
puts "\n\n" + "=" * 60
puts "🎯 HelpForce Key Features Summary:"
puts "=" * 60
puts "
✅ Multi-Model AI Support (OpenAI, Claude, Gemini)
✅ Smart Conversation Routing with ML
✅ AI Agent Marketplace with 6 specialized agents
✅ Real-time sentiment analysis
✅ Professional text rephrasing
✅ Comprehensive analytics dashboard
✅ Agent performance tracking
✅ Seamless Chatwoot integration

🌐 Access the full dashboard at:
   http://localhost:3000/app/accounts/1/settings/helpforce

🔐 Login: admin@helpforce.test / Password123!
"

puts "\n✨ Demo Complete!"