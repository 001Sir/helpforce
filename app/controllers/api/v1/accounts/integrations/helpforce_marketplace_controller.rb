class Api::V1::Accounts::Integrations::HelpforceMarketplaceController < Api::V1::Accounts::BaseController
  before_action :check_authorization
  before_action :find_agent, only: [:show, :install, :uninstall, :configure, :test]

  def index
    # Get all available agents from marketplace
    agents = Helpforce::Marketplace::AgentRegistry.all_agents
    installed_agents = current_account.helpforce_agents.pluck(:agent_id)

    marketplace_data = agents.map do |agent_id, agent_info|
      {
        id: agent_id,
        **agent_info,
        installed: installed_agents.include?(agent_id),
        installation_count: HelpforceAgent.where(agent_id: agent_id).count
      }
    end

    # Apply filters
    if params[:category].present?
      marketplace_data = marketplace_data.select { |agent| agent[:category] == params[:category] }
    end

    if params[:pricing].present?
      marketplace_data = marketplace_data.select { |agent| agent[:pricing] == params[:pricing] }
    end

    if params[:search].present?
      query = params[:search].downcase
      marketplace_data = marketplace_data.select do |agent|
        agent[:name].downcase.include?(query) ||
        agent[:description].downcase.include?(query) ||
        agent[:capabilities].any? { |cap| cap.downcase.include?(query) }
      end
    end

    render json: {
      agents: marketplace_data,
      categories: Helpforce::Marketplace::AgentRegistry.agent_categories,
      installed_count: installed_agents.count,
      total_available: agents.count
    }
  end

  def show
    installed_agent = current_account.helpforce_agents.find_by(agent_id: params[:id])
    
    render json: {
      **@agent_info,
      installed: installed_agent.present?,
      installation_details: installed_agent&.as_json(
        include: [:performance_summary, :daily_metrics]
      ),
      recommended_for_account: agent_recommendation_score,
      similar_agents: find_similar_agents
    }
  end

  def install
    # Check if agent is already installed
    existing_agent = current_account.helpforce_agents.find_by(agent_id: params[:id])
    if existing_agent
      return render json: { error: 'Agent is already installed' }, status: :unprocessable_entity
    end

    # Check premium requirements
    if @agent_info[:pricing] == 'premium' && !account_has_premium_access?
      return render json: { 
        error: 'Premium subscription required for this agent',
        upgrade_required: true 
      }, status: :payment_required
    end

    begin
      agent = current_account.helpforce_agents.create!(
        agent_id: params[:id],
        name: @agent_info[:name],
        description: @agent_info[:description],
        category: @agent_info[:category],
        ai_provider: determine_best_provider_for_agent,
        user: current_user
      )

      # Set up default configuration
      setup_agent_defaults(agent)

      render json: {
        success: true,
        message: "#{@agent_info[:name]} installed successfully",
        agent: agent.as_json(include: :marketplace_info)
      }
    rescue => e
      render json: { error: "Installation failed: #{e.message}" }, status: :internal_server_error
    end
  end

  def uninstall
    agent = current_account.helpforce_agents.find_by(agent_id: params[:id])
    unless agent
      return render json: { error: 'Agent not installed' }, status: :not_found
    end

    begin
      agent_name = agent.name
      agent.destroy!

      render json: {
        success: true,
        message: "#{agent_name} uninstalled successfully"
      }
    rescue => e
      render json: { error: "Uninstallation failed: #{e.message}" }, status: :internal_server_error
    end
  end

  def configure
    agent = current_account.helpforce_agents.find_by(agent_id: params[:id])
    unless agent
      return render json: { error: 'Agent not installed' }, status: :not_found
    end

    configuration = params[:configuration] || {}
    
    begin
      agent.update!(
        ai_provider: configuration[:ai_provider] || agent.ai_provider,
        ai_model: configuration[:ai_model] || agent.ai_model,
        temperature: configuration[:temperature] || agent.temperature,
        max_tokens: configuration[:max_tokens] || agent.max_tokens,
        custom_prompt: configuration[:custom_prompt] || agent.custom_prompt,
        auto_respond: configuration[:auto_respond] || agent.auto_respond,
        trigger_conditions: configuration[:trigger_conditions] || agent.trigger_conditions
      )

      render json: {
        success: true,
        message: 'Agent configuration updated',
        agent: agent.as_json
      }
    rescue => e
      render json: { error: "Configuration failed: #{e.message}" }, status: :internal_server_error
    end
  end

  def test
    agent = current_account.helpforce_agents.find_by(agent_id: params[:id])
    unless agent
      return render json: { error: 'Agent not installed' }, status: :not_found
    end

    test_message = params[:test_message] || "Hello, can you help me with a test inquiry?"

    begin
      # Create a test conversation for testing
      test_conversation = current_account.conversations.build(
        display_id: "test-#{SecureRandom.hex(4)}",
        status: 'open'
      )

      response = agent.process_message(test_message, test_conversation)

      render json: {
        success: true,
        test_message: test_message,
        agent_response: response,
        response_time: agent.agent_conversations.last&.response_time,
        provider_used: agent.ai_provider,
        model_used: agent.ai_model
      }
    rescue => e
      render json: { error: "Test failed: #{e.message}" }, status: :internal_server_error
    end
  end

  def installed
    # Get all installed agents for the account
    agents = current_account.helpforce_agents.includes(:agent_conversations, :agent_metrics)
    
    agents_data = agents.map do |agent|
      {
        **agent.as_json,
        marketplace_info: agent.marketplace_info,
        performance: agent.performance_summary,
        recent_activity: agent.agent_conversations.order(created_at: :desc).limit(5)
      }
    end

    render json: {
      installed_agents: agents_data,
      total_installed: agents.count,
      active_agents: agents.active.count,
      performance_overview: calculate_overall_performance(agents)
    }
  end

  def recommendations
    # Get agent recommendations based on conversation history
    conversation_id = params[:conversation_id]
    conversation = current_account.conversations.find_by(id: conversation_id) if conversation_id

    if conversation
      recommended_agent_ids = Helpforce::Marketplace::AgentRegistry.recommended_agents_for_conversation(conversation)
      recommendations = recommended_agent_ids.map do |agent_id|
        agent_info = Helpforce::Marketplace::AgentRegistry.get_agent(agent_id)
        installed_agent = current_account.helpforce_agents.find_by(agent_id: agent_id)
        
        {
          id: agent_id,
          **agent_info,
          installed: installed_agent.present?,
          fit_score: installed_agent&.analyze_conversation_fit(conversation)
        }
      end

      render json: {
        conversation_id: conversation.id,
        recommendations: recommendations,
        conversation_summary: summarize_conversation(conversation)
      }
    else
      # General recommendations based on account usage patterns
      render json: {
        general_recommendations: get_general_recommendations,
        trending_agents: get_trending_agents,
        suggested_categories: suggest_categories_for_account
      }
    end
  end

  def analytics
    # Agent marketplace analytics
    time_range = params[:time_range] || '30d'
    
    analytics_data = {
      installation_trends: get_installation_trends(time_range),
      popular_agents: get_popular_agents(time_range),
      category_distribution: get_category_distribution,
      performance_metrics: get_performance_metrics(time_range),
      usage_statistics: get_usage_statistics(time_range)
    }

    render json: analytics_data
  end

  private

  def find_agent
    @agent_info = Helpforce::Marketplace::AgentRegistry.get_agent(params[:id])
    unless @agent_info
      render json: { error: 'Agent not found in marketplace' }, status: :not_found
    end
  end

  def check_authorization
    authorize(current_account, :admin?)
  end

  def account_has_premium_access?
    # Check if account has premium subscription
    # This would integrate with your billing system
    true # For now, allow all premium features
  end

  def determine_best_provider_for_agent
    recommended_providers = @agent_info[:provider_recommendations]
    ai_service = Helpforce::Ai::MultiModelService.new(account: current_account)
    
    # Find first configured provider from recommendations
    recommended_providers.find { |provider| ai_service.provider_configured?(provider) } ||
    ai_service.get_default_provider
  end

  def setup_agent_defaults(agent)
    # Set up any default configurations specific to the agent
    case agent.agent_id
    when 'technical_support'
      agent.update!(
        temperature: 0.5, # More consistent responses for technical issues
        max_tokens: 3000   # Longer responses for detailed explanations
      )
    when 'sales_assistant'
      agent.update!(
        temperature: 0.8,  # More creative and persuasive
        auto_respond: false # Sales should be more careful about auto-responses
      )
    when 'multilingual_support'
      agent.update!(
        max_tokens: 2500   # Allow for longer translations
      )
    end
  end

  def agent_recommendation_score
    # Calculate how well this agent fits the account's needs
    # Based on conversation history, current issues, etc.
    75 # Placeholder score
  end

  def find_similar_agents
    # Find agents in the same category or with similar capabilities
    current_category = @agent_info[:category]
    similar = Helpforce::Marketplace::AgentRegistry.agents_by_category(current_category)
    similar.reject { |id, _| id == params[:id] }.keys.first(3)
  end

  def calculate_overall_performance(agents)
    return {} if agents.empty?

    total_conversations = agents.sum { |agent| agent.agent_conversations.count }
    total_tokens = agents.sum { |agent| agent.agent_conversations.sum(:tokens_used) }
    avg_response_time = agents.map { |agent| agent.agent_conversations.average(:response_time) }.compact.sum / agents.count

    {
      total_conversations: total_conversations,
      total_tokens_used: total_tokens,
      average_response_time: avg_response_time,
      most_active_agent: agents.max_by { |agent| agent.agent_conversations.count }&.name
    }
  end

  def summarize_conversation(conversation)
    # Create a brief summary of the conversation
    messages = conversation.messages.last(5).map(&:content).join(' ')
    messages.truncate(200)
  end

  def get_general_recommendations
    # Return generally popular and useful agents
    ['technical_support', 'billing_support', 'onboarding_guide'].map do |agent_id|
      {
        id: agent_id,
        **Helpforce::Marketplace::AgentRegistry.get_agent(agent_id),
        reason: 'Popular choice for most businesses'
      }
    end
  end

  def get_trending_agents
    # Agents that are being installed frequently
    trending_ids = HelpforceAgent.group(:agent_id)
                                 .where(created_at: 7.days.ago..Time.current)
                                 .order('COUNT(*) DESC')
                                 .limit(3)
                                 .pluck(:agent_id)

    trending_ids.map do |agent_id|
      Helpforce::Marketplace::AgentRegistry.get_agent(agent_id)
    end.compact
  end

  def suggest_categories_for_account
    # Suggest categories based on account's conversation patterns
    ['technical', 'billing', 'onboarding']
  end

  def get_installation_trends(time_range)
    # Analytics helper methods would be implemented here
    { trend: 'increasing', period: time_range }
  end

  def get_popular_agents(time_range)
    HelpforceAgent.group(:agent_id)
                  .where(created_at: parse_time_range(time_range))
                  .order('COUNT(*) DESC')
                  .limit(5)
                  .count
  end

  def get_category_distribution
    current_account.helpforce_agents.group(:category).count
  end

  def get_performance_metrics(time_range)
    agents = current_account.helpforce_agents
    {
      total_interactions: agents.joins(:agent_conversations).count,
      average_response_time: agents.joins(:agent_conversations).average('agent_conversations.response_time'),
      total_tokens_used: agents.joins(:agent_conversations).sum('agent_conversations.tokens_used')
    }
  end

  def get_usage_statistics(time_range)
    {
      active_agents: current_account.helpforce_agents.active.count,
      conversations_handled: current_account.helpforce_agents.joins(:agent_conversations).count,
      most_used_provider: current_account.helpforce_agents.group(:ai_provider).order('COUNT(*) DESC').first&.first
    }
  end

  def parse_time_range(time_range)
    case time_range
    when '7d'
      7.days.ago..Time.current
    when '30d'
      30.days.ago..Time.current
    when '90d'
      90.days.ago..Time.current
    else
      30.days.ago..Time.current
    end
  end
end