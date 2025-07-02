#!/usr/bin/env ruby
# Create demo data for HelpForce platform demonstration

puts "Creating HelpForce Demo Data..."
puts "=" * 50

# Get the first account and admin user
account = Account.first
admin_user = User.find_by(email: 'admin@helpforce.test')

unless account && admin_user
  puts "❌ Error: Account or admin user not found!"
  exit
end

puts "Using account: #{account.name} (ID: #{account.id})"
puts "Admin user: #{admin_user.email}"

# Create or find an inbox for testing
inbox = account.inboxes.first || account.inboxes.create!(
  name: 'HelpForce Demo Inbox',
  channel: Channel::WebWidget.create!(
    account: account,
    website_url: 'https://helpforce.demo',
    widget_color: '#1f93ff'
  )
)

puts "\n📥 Using inbox: #{inbox.name}"

# Create test contacts with different types of issues
contacts_data = [
  {
    name: 'John Technical',
    email: 'john.tech@example.com',
    phone_number: '+1234567890',
    issue_type: 'technical'
  },
  {
    name: 'Sarah Billing',
    email: 'sarah.billing@example.com', 
    phone_number: '+1234567891',
    issue_type: 'billing'
  },
  {
    name: 'Mike Newuser',
    email: 'mike.new@example.com',
    phone_number: '+1234567892',
    issue_type: 'onboarding'
  },
  {
    name: 'Emma Urgent',
    email: 'emma.urgent@example.com',
    phone_number: '+1234567893',
    issue_type: 'urgent'
  },
  {
    name: 'Carlos Spanish',
    email: 'carlos.es@example.com',
    phone_number: '+1234567894',
    issue_type: 'multilingual'
  }
]

# Sample messages for different issue types
messages_by_type = {
  'technical' => [
    "Hi, I'm getting an error when trying to upload files",
    "The error says 'File size too large' but my file is only 2MB",
    "I've tried different browsers but still getting the same error",
    "This is blocking my work, please help!"
  ],
  'billing' => [
    "Hello, I was charged twice for my subscription this month",
    "I see two charges of $99 on my credit card statement",
    "My invoice number is INV-2024-001",
    "Can you please refund the duplicate charge?"
  ],
  'onboarding' => [
    "Hi! I just signed up for your service",
    "I'm not sure where to start or what features to use first",
    "Can someone guide me through the initial setup?",
    "I want to make sure I'm using everything correctly"
  ],
  'urgent' => [
    "URGENT: Our entire system is down!",
    "None of our team can access the platform",
    "This is affecting our business operations",
    "We need immediate assistance, please escalate this!"
  ],
  'multilingual' => [
    "Hola, necesito ayuda con mi cuenta",
    "No puedo cambiar mi contraseña",
    "¿Pueden ayudarme en español?",
    "Gracias por su ayuda"
  ]
}

puts "\n👥 Creating contacts and conversations..."

contacts_data.each do |contact_data|
  # Create contact
  contact = account.contacts.find_or_create_by!(email: contact_data[:email]) do |c|
    c.name = contact_data[:name]
    c.phone_number = contact_data[:phone_number]
  end
  
  # Ensure contact is associated with inbox
  contact_inbox = inbox.contact_inboxes.find_or_create_by!(contact: contact) do |ci|
    ci.source_id = SecureRandom.uuid
    ci.hmac_verified = true
  end
  
  # Create conversation
  conversation = account.conversations.create!(
    inbox: inbox,
    contact: contact,
    contact_inbox: contact_inbox,
    status: 'open'
  )
  
  # Create messages
  messages = messages_by_type[contact_data[:issue_type]]
  
  messages.each_with_index do |content, index|
    conversation.messages.create!(
      account: account,
      content: content,
      message_type: 'incoming',
      inbox: inbox,
      sender: contact,
      created_at: (4 - index).minutes.ago
    )
  end
  
  puts "✅ Created conversation ##{conversation.display_id} for #{contact.name} (#{contact_data[:issue_type]} issue)"
end

# Create some resolved conversations for analytics
puts "\n📊 Creating historical data for analytics..."

5.times do |i|
  contact = account.contacts.find_or_create_by!(email: "history#{i + 1}@example.com") do |c|
    c.name = "Historical User #{i + 1}"
  end
  
  # Ensure contact is associated with inbox
  contact_inbox = inbox.contact_inboxes.find_or_create_by!(contact: contact) do |ci|
    ci.source_id = SecureRandom.uuid
    ci.hmac_verified = true
  end
  
  conversation = account.conversations.create!(
    inbox: inbox,
    contact: contact,
    contact_inbox: contact_inbox,
    status: 'resolved',
    created_at: (i + 1).days.ago,
    updated_at: (i + 1).days.ago + 2.hours
  )
  
  # Assign to a random HelpForce agent
  agent = account.helpforce_agents.sample
  if agent
    ConversationAgentAssignment.create!(
      conversation: conversation,
      helpforce_agent: agent,
      assignment_reason: "Auto-routed based on content analysis",
      confidence_score: rand(70..95),
      auto_assigned: true,
      assigned_at: conversation.created_at,
      unassigned_at: conversation.updated_at
    )
  end
end

puts "✅ Created 5 historical resolved conversations"

# Test AI features
puts "\n🤖 Testing AI features..."

# Test sentiment analysis
test_messages = [
  "I'm really frustrated with this service!",
  "This is amazing, thank you so much!",
  "Can you help me with my account?"
]

ai_service = Helpforce::Ai::MultiModelService.new(account: account)

test_messages.each do |msg|
  begin
    sentiment = ai_service.extract_sentiment(msg)
    puts "📝 Message: '#{msg}'"
    puts "   Sentiment: #{sentiment}"
  rescue => e
    puts "❌ Sentiment analysis error: #{e.message}"
  end
end

# Test text rephrasing
begin
  original = "hey can u fix this asap plz"
  rephrased = ai_service.rephrase_text(original, style: 'professional')
  puts "\n✏️  Rephrase Test:"
  puts "   Original: '#{original}'"
  puts "   Professional: '#{rephrased[:content]}'"
rescue => e
  puts "❌ Rephrasing error: #{e.message}"
end

# Display summary
puts "\n" + "=" * 50
puts "📊 HelpForce Demo Data Summary:"
puts "=" * 50

puts "\n🏢 Account: #{account.name}"
puts "👤 Admin: #{admin_user.email}"
puts "📥 Inbox: #{inbox.name}"
puts "\n🤖 HelpForce Agents:"
account.helpforce_agents.each do |agent|
  puts "   - #{agent.name} (#{agent.category}) - #{agent.status}"
end

puts "\n💬 Conversations:"
puts "   - Open: #{account.conversations.open.count}"
puts "   - Resolved: #{account.conversations.resolved.count}"
puts "   - Total: #{account.conversations.count}"

puts "\n🔄 Agent Assignments:"
puts "   - Total: #{ConversationAgentAssignment.joins(:helpforce_agent).where(helpforce_agents: { account: account }).count}"
puts "   - Auto-routed: #{ConversationAgentAssignment.joins(:helpforce_agent).where(helpforce_agents: { account: account }).auto_assigned.count}"

puts "\n✅ Demo data created successfully!"
puts "\n🌐 Access HelpForce Dashboard at:"
puts "   http://localhost:3000/app/accounts/#{account.id}/settings/helpforce"
puts "\n🔑 Login with:"
puts "   Email: admin@helpforce.test"
puts "   Password: Password123!"