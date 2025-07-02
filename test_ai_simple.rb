#!/usr/bin/env ruby
# Test available AI endpoints

require 'net/http'
require 'json'
require 'uri'

API_TOKEN = '81ouad8exqFUufXqhU5reg6c'
BASE_URL = 'http://localhost:3000/api/v1/accounts/1/integrations'

puts "Testing Available HelpForce AI Endpoints"
puts "=" * 50

# 1. Test sentiment analysis
puts "\n1. Testing Sentiment Analysis..."
uri = URI("#{BASE_URL}/helpforce_ai/analyze_sentiment")
request = Net::HTTP::Post.new(uri)
request['Accept'] = 'application/json'
request['Content-Type'] = 'application/json'
request['api_access_token'] = API_TOKEN
request.body = {
  text: "I'm really frustrated with this service! The error keeps happening."
}.to_json

response = Net::HTTP.start(uri.hostname, uri.port) do |http|
  http.request(request)
end

if response.code == '200'
  result = JSON.parse(response.body)
  puts "✅ Sentiment: #{result['sentiment']} (confidence: #{result['confidence']})"
else
  puts "❌ Failed: #{response.code}"
end

# 2. Test rephrasing
puts "\n2. Testing Text Rephrasing..."
uri = URI("#{BASE_URL}/helpforce_ai/rephrase_text")
request = Net::HTTP::Post.new(uri)
request['Accept'] = 'application/json'
request['Content-Type'] = 'application/json'
request['api_access_token'] = API_TOKEN
request.body = {
  text: "hey can u fix this asap plz",
  style: "professional"
}.to_json

response = Net::HTTP.start(uri.hostname, uri.port) do |http|
  http.request(request)
end

if response.code == '200'
  result = JSON.parse(response.body)
  puts "✅ Rephrased: #{result['content']}"
else
  puts "❌ Failed: #{response.code}"
end

# 3. Test chat completion
puts "\n3. Testing Chat Completion..."
uri = URI("#{BASE_URL}/helpforce_ai/chat_completion")
request = Net::HTTP::Post.new(uri)
request['Accept'] = 'application/json'
request['Content-Type'] = 'application/json'
request['api_access_token'] = API_TOKEN
request.body = {
  messages: [
    {
      role: "system",
      content: "You are a helpful technical support agent. The customer is having file upload issues."
    },
    {
      role: "user", 
      content: "The error says 'File size too large' but my file is only 2MB"
    }
  ],
  temperature: 0.7
}.to_json

response = Net::HTTP.start(uri.hostname, uri.port) do |http|
  http.request(request)
end

if response.code == '200'
  result = JSON.parse(response.body)
  puts "✅ AI Response:"
  puts result['content']
else
  puts "❌ Failed: #{response.code}"
end

puts "\n" + "=" * 50
puts "Testing Complete!"