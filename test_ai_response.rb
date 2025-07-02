#!/usr/bin/env ruby
# Test AI agent response generation

require 'net/http'
require 'json'
require 'uri'

API_TOKEN = '81ouad8exqFUufXqhU5reg6c'
BASE_URL = 'http://localhost:3000/api/v1/accounts/1/integrations'

# Test AI features
puts "Testing HelpForce AI Agent Responses"
puts "=" * 50

# 1. Get a conversation with an assigned agent
conversation_id = 14  # The one we just routed
agent_id = 1          # Technical Support Specialist

# 2. Generate suggested response
puts "\n1. Testing Suggested Response Generation..."
uri = URI("#{BASE_URL}/helpforce_ai/conversations/#{conversation_id}/suggest_response")
request = Net::HTTP::Post.new(uri)
request['Accept'] = 'application/json'
request['Content-Type'] = 'application/json'
request['api_access_token'] = API_TOKEN
request.body = {
  agent_id: agent_id,
  context: "Customer is experiencing technical issues with file upload. Error: 'File size too large' but file is only 2MB."
}.to_json

response = Net::HTTP.start(uri.hostname, uri.port) do |http|
  http.request(request)
end

if response.code == '200'
  result = JSON.parse(response.body)
  puts "✅ Suggested Response Generated!"
  puts "\nSuggestions:"
  result['suggestions'].each_with_index do |suggestion, i|
    puts "\n#{i + 1}. #{suggestion['tone'].capitalize} tone:"
    puts "   #{suggestion['content']}"
  end
else
  puts "❌ Failed: #{response.code} - #{response.body[0..200]}"
end

# 3. Generate full AI response
puts "\n\n2. Testing Full AI Response Generation..."
uri = URI("#{BASE_URL}/helpforce_ai/conversations/#{conversation_id}/generate_response")
request = Net::HTTP::Post.new(uri)
request['Accept'] = 'application/json'
request['Content-Type'] = 'application/json'
request['api_access_token'] = API_TOKEN
request.body = {
  agent_id: agent_id,
  tone: "professional"
}.to_json

response = Net::HTTP.start(uri.hostname, uri.port) do |http|
  http.request(request)
end

if response.code == '200'
  result = JSON.parse(response.body)
  puts "✅ AI Response Generated!"
  puts "\nGenerated Response:"
  puts result['response']['content']
  puts "\nMetadata:"
  puts "- Processing time: #{result['response']['processing_time']}ms"
  puts "- Tokens used: #{result['response']['tokens_used']}"
  puts "- Model: #{result['response']['model']}"
else
  puts "❌ Failed: #{response.code} - #{response.body[0..200]}"
end

# 4. Test sending the response
puts "\n\n3. Testing Send AI Response..."
uri = URI("#{BASE_URL}/helpforce_ai/conversations/#{conversation_id}/send_response")
request = Net::HTTP::Post.new(uri)
request['Accept'] = 'application/json'
request['Content-Type'] = 'application/json'
request['api_access_token'] = API_TOKEN
request.body = {
  agent_id: agent_id,
  content: "I understand you're experiencing an issue with file uploads. The 'File size too large' error typically occurs when the file exceeds our system limits. Let me help you resolve this:\n\n1. First, can you confirm the exact file size and format?\n2. Are you uploading through our web interface or API?\n3. Have you tried compressing the file or splitting it into smaller parts?\n\nI'll guide you through the appropriate solution once I have these details.",
  tone: "professional"
}.to_json

response = Net::HTTP.start(uri.hostname, uri.port) do |http|
  http.request(request)
end

if response.code == '200'
  result = JSON.parse(response.body)
  puts "✅ Response Sent Successfully!"
  puts "Message ID: #{result['message']['id']}"
else
  puts "❌ Failed: #{response.code} - #{response.body[0..200]}"
end

puts "\n" + "=" * 50
puts "AI Response Testing Complete!"