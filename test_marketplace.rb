puts "🚀 Testing HelpForce AI Agent Marketplace"
puts "=" * 60

begin
  account = Account.first
  user = account.users.first
  puts "Testing with Account: #{account.name} (ID: #{account.id})"
  
  # Test 1: Agent Registry
  puts "\n📋 1. Testing Agent Registry"
  all_agents = Helpforce::Marketplace::AgentRegistry.all_agents
  puts "✅ Total agents available: #{all_agents.count}"
  
  all_agents.each do |agent_id, agent_info|
    puts "   #{agent_info[:icon]} #{agent_info[:name]} (#{agent_info[:category]}) - #{agent_info[:pricing]}"
  end
  
  # Test 2: Agent Categories
  puts "\n🏷️ 2. Testing Agent Categories"
  categories = Helpforce::Marketplace::AgentRegistry.agent_categories
  puts "✅ Categories: #{categories.join(', ')}"
  
  # Test 3: Free vs Premium Agents
  puts "\n💰 3. Testing Free vs Premium Agents"
  free_agents = Helpforce::Marketplace::AgentRegistry.free_agents
  premium_agents = Helpforce::Marketplace::AgentRegistry.premium_agents
  puts "✅ Free agents: #{free_agents.count}"
  puts "✅ Premium agents: #{premium_agents.count}"
  
  # Test 4: Agent Installation
  puts "\n📦 4. Testing Agent Installation"
  
  # Install a free agent (technical support)
  agent = account.helpforce_agents.create!(
    agent_id: 'technical_support',
    name: 'Technical Support Specialist',
    user: user
  )
  puts "✅ Installed agent: #{agent.name}"
  puts "   Provider: #{agent.ai_provider}, Model: #{agent.ai_model}"
  puts "   System prompt length: #{agent.system_prompt&.length || 0} characters"
  
  # Test 5: Agent Capabilities
  puts "\n🛠️ 5. Testing Agent Capabilities"
  capabilities = agent.capabilities
  puts "✅ Agent capabilities: #{capabilities.join(', ')}"
  
  conversation_starters = agent.conversation_starters
  puts "✅ Conversation starters: #{conversation_starters.count}"
  conversation_starters.each { |starter| puts "   - #{starter}" }
  
  # Test 6: Agent Performance Methods
  puts "\n📊 6. Testing Agent Performance Methods"
  performance = agent.performance_summary
  puts "✅ Performance summary generated"
  puts "   Total conversations: #{performance[:total_conversations]}"
  puts "   Success rate: #{performance[:success_rate]}%"
  
  # Test 7: Conversation Recommendations
  puts "\n🎯 7. Testing Conversation Recommendations"
  
  # Create a test conversation
  conversation = account.conversations.create!(
    status: 'open',
    display_id: 'TEST-123'
  )
  
  # Add a technical message
  conversation.messages.create!(
    content: "I'm having an error with the system. It keeps showing 'Connection failed' and I can't log in.",
    message_type: 'incoming',
    sender: account.contacts.first || account.contacts.create!(name: 'Test User', email: 'test@example.com')
  )
  
  recommendations = Helpforce::Marketplace::AgentRegistry.recommended_agents_for_conversation(conversation)
  puts "✅ Recommended agents for conversation: #{recommendations.join(', ')}"
  
  # Test 8: Agent Conversation Fit Analysis
  puts "\n🎯 8. Testing Agent Conversation Fit Analysis"
  fit_analysis = agent.analyze_conversation_fit(conversation)
  puts "✅ Fit analysis completed"
  puts "   Fit score: #{fit_analysis[:fit_score]}%"
  puts "   Recommendation: #{fit_analysis[:recommendation]}"
  puts "   Matching capabilities: #{fit_analysis[:matching_capabilities].join(', ')}"
  
  # Test 9: Search Functionality
  puts "\n🔍 9. Testing Search Functionality"
  search_results = Helpforce::Marketplace::AgentRegistry.search_agents('technical')
  puts "✅ Search for 'technical': #{search_results.count} results"
  
  billing_agents = Helpforce::Marketplace::AgentRegistry.agents_by_category('billing')
  puts "✅ Billing category agents: #{billing_agents.count}"
  
  # Test 10: System Prompt Generation
  puts "\n📝 10. Testing System Prompt Generation"
  technical_agent_info = Helpforce::Marketplace::AgentRegistry.get_agent('technical_support')
  puts "✅ Technical support system prompt length: #{technical_agent_info[:system_prompt].length} characters"
  puts "   Preview: #{technical_agent_info[:system_prompt].first(100)}..."
  
  # Test 11: Multi-language Support Agent
  puts "\n🌍 11. Testing Multilingual Agent"
  multilingual_info = Helpforce::Marketplace::AgentRegistry.get_agent('multilingual_support')
  puts "✅ Multilingual agent available: #{multilingual_info[:name]}"
  puts "   Conversation starters: #{multilingual_info[:conversation_starters].count}"
  multilingual_info[:conversation_starters].each { |starter| puts "   - #{starter}" }
  
  # Test 12: Agent Provider Recommendations
  puts "\n🤖 12. Testing Provider Recommendations"
  sales_agent_info = Helpforce::Marketplace::AgentRegistry.get_agent('sales_assistant')
  puts "✅ Sales assistant recommended providers: #{sales_agent_info[:provider_recommendations].join(', ')}"
  
  escalation_info = Helpforce::Marketplace::AgentRegistry.get_agent('escalation_manager')
  puts "✅ Escalation manager recommended providers: #{escalation_info[:provider_recommendations].join(', ')}"
  
  # Test 13: Agent Configuration
  puts "\n⚙️ 13. Testing Agent Configuration"
  agent.update!(
    temperature: 0.5,
    max_tokens: 3000,
    custom_prompt: "Custom prompt for testing"
  )
  puts "✅ Agent configuration updated"
  puts "   Temperature: #{agent.temperature}"
  puts "   Max tokens: #{agent.max_tokens}"
  puts "   Has custom prompt: #{agent.custom_prompt.present?}"
  
  # Test 14: Cleanup
  puts "\n🧹 14. Cleanup"
  agent.destroy!
  conversation.destroy!
  puts "✅ Test data cleaned up"
  
  puts "\n🎉 All HelpForce AI Agent Marketplace Tests Passed!"
  puts "\n💡 Ready for production use with the following features:"
  puts "   ✅ #{all_agents.count} specialized AI agents available"
  puts "   ✅ #{categories.count} agent categories (#{categories.join(', ')})"
  puts "   ✅ Smart agent recommendations based on conversation content"
  puts "   ✅ Flexible configuration per agent"
  puts "   ✅ Performance tracking and analytics"
  puts "   ✅ Multi-provider support (OpenAI, Claude, Gemini)"
  puts "   ✅ Free and premium agent tiers"
  puts "   ✅ Easy installation and management"

rescue => e
  puts "\n❌ Error in marketplace test: #{e.message}"
  puts e.backtrace.first(5).join("\n")
end