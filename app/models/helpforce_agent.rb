# == Schema Information
#
# Table name: helpforce_agents
#
#  id                 :bigint           not null, primary key
#  ai_model           :string
#  ai_provider        :string           default("openai")
#  auto_respond       :boolean          default(FALSE)
#  category           :string
#  configuration      :json
#  custom_prompt      :text
#  description        :text
#  last_used_at       :datetime
#  max_tokens         :integer          default(2000)
#  metrics_data       :json
#  name               :string           not null
#  status             :string           default("active")
#  temperature        :decimal(3, 2)    default(0.7)
#  trigger_conditions :json
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  account_id         :bigint           not null
#  agent_id           :string           not null
#  user_id            :bigint
#
# Indexes
#
#  index_helpforce_agents_on_account_id               (account_id)
#  index_helpforce_agents_on_account_id_and_agent_id  (account_id,agent_id) UNIQUE
#  index_helpforce_agents_on_account_id_and_category  (account_id,category)
#  index_helpforce_agents_on_account_id_and_status    (account_id,status)
#  index_helpforce_agents_on_ai_provider              (ai_provider)
#  index_helpforce_agents_on_user_id                  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (user_id => users.id)
#
class HelpforceAgent < ApplicationRecord
  belongs_to :account
  belongs_to :user, optional: true
  has_many :agent_conversations, dependent: :destroy
  has_many :conversations, through: :agent_conversations
  has_many :agent_metrics, dependent: :destroy
  has_many :conversation_agent_assignments, dependent: :destroy
  has_many :assigned_conversations, through: :conversation_agent_assignments, source: :conversation

  validates :agent_id, presence: true, uniqueness: { scope: :account_id }
  validates :name, presence: true
  validates :status, inclusion: { in: %w[active inactive] }
  validates :ai_provider, inclusion: { in: %w[openai claude gemini] }

  enum status: { active: 'active', inactive: 'inactive' }

  scope :active, -> { where(status: 'active') }
  scope :by_category, ->(category) { where(category: category) }
  scope :by_provider, ->(provider) { where(ai_provider: provider) }

  before_validation :set_defaults, on: :create
  before_save :update_configuration

  def agent_definition
    @agent_definition ||= Helpforce::Marketplace::AgentRegistry.get_agent(agent_id)
  end

  def marketplace_info
    agent_definition
  end

  def system_prompt
    custom_prompt.presence || agent_definition&.dig(:system_prompt)
  end

  def capabilities
    agent_definition&.dig(:capabilities) || []
  end

  def conversation_starters
    agent_definition&.dig(:conversation_starters) || []
  end

  def suggested_responses
    agent_definition&.dig(:suggested_responses) || {}
  end

  def icon
    agent_definition&.dig(:icon) || '🤖'
  end

  def is_premium?
    agent_definition&.dig(:pricing) == 'premium'
  end

  def recommended_providers
    agent_definition&.dig(:provider_recommendations) || ['openai']
  end

  def process_message(message, conversation)
    # Use the multi-model AI service to process the message
    ai_service = Helpforce::Ai::MultiModelService.new(account: account)
    
    # Build conversation context
    context_messages = build_conversation_context(conversation)
    
    # Add system prompt
    messages = [
      { role: 'system', content: system_prompt },
      *context_messages,
      { role: 'user', content: message }
    ]

    # Generate response using specified provider
    result = ai_service.chat_completion(
      messages,
      provider: ai_provider,
      model: ai_model,
      temperature: temperature,
      max_tokens: max_tokens
    )

    # Track metrics
    track_usage(result)

    # Create agent conversation record
    agent_conversations.create!(
      conversation: conversation,
      message_content: message,
      response_content: result[:content],
      ai_provider: result[:provider],
      ai_model: result[:model],
      response_time: Time.current - Time.current, # This would be calculated properly
      tokens_used: result[:usage]&.dig(:total_tokens)
    )

    result[:content]
  rescue => e
    Rails.logger.error("HelpForce Agent #{name} error: #{e.message}")
    "I apologize, but I'm experiencing technical difficulties. Please try again or contact a human agent."
  end

  def suggest_response_for_conversation(conversation)
    # Suggest an appropriate response based on conversation context
    ai_service = Helpforce::Ai::MultiModelService.new(account: account)
    
    context_messages = build_conversation_context(conversation)
    
    prompt = "Based on this conversation, suggest a helpful response that aligns with my role as #{name}. " \
             "Consider my capabilities: #{capabilities.join(', ')}. " \
             "Provide only the suggested response text."

    messages = [
      { role: 'system', content: system_prompt },
      { role: 'user', content: "#{context_messages.map { |m| "#{m[:role]}: #{m[:content]}" }.join("\n")}\n\n#{prompt}" }
    ]

    result = ai_service.chat_completion(messages, provider: ai_provider, model: ai_model)
    result[:content]
  end

  def analyze_conversation_fit(conversation)
    # Determine how well this agent fits the conversation
    content = conversation.messages.last(10).map(&:content).join(' ')
    
    agent_keywords = capabilities + [category]
    matches = agent_keywords.count { |keyword| content.downcase.include?(keyword.downcase) }
    
    {
      fit_score: (matches.to_f / agent_keywords.length * 100).round,
      matching_capabilities: capabilities.select { |cap| content.downcase.include?(cap.downcase) },
      recommendation: matches > 0 ? 'recommended' : 'not_recommended'
    }
  end

  def daily_metrics
    agent_metrics.where(created_at: Date.current.beginning_of_day..Date.current.end_of_day)
  end

  def weekly_metrics
    agent_metrics.where(created_at: 1.week.ago..Time.current)
  end

  def performance_summary
    {
      total_conversations: agent_conversations.count,
      active_conversations: agent_conversations.joins(:conversation).where(conversations: { status: 'open' }).count,
      average_response_time: agent_conversations.average(:response_time),
      total_tokens_used: agent_conversations.sum(:tokens_used),
      success_rate: calculate_success_rate,
      most_used_capability: find_most_used_capability
    }
  end

  private

  def set_defaults
    if agent_definition
      self.name ||= agent_definition[:name]
      self.description ||= agent_definition[:description]
      self.category ||= agent_definition[:category]
      self.ai_provider ||= agent_definition[:provider_recommendations]&.first || 'openai'
      self.status ||= 'active'
      self.temperature ||= 0.7
      self.max_tokens ||= 2000
    end
  end

  def update_configuration
    # Validate AI provider is available for account
    unless account.present?
      errors.add(:ai_provider, "Account is required")
      throw :abort
    end

    ai_service = Helpforce::Ai::MultiModelService.new(account: account)
    unless ai_service.provider_configured?(ai_provider)
      errors.add(:ai_provider, "#{ai_provider} is not configured for this account")
      throw :abort
    end

    # Set default model if not specified
    if ai_model.blank?
      available_models = ai_service.get_provider_models(ai_provider)
      self.ai_model = available_models.first if available_models.any?
    end
  end

  def build_conversation_context(conversation, limit: 10)
    conversation.messages.order(:created_at).last(limit).map do |message|
      {
        role: message.outgoing? ? 'assistant' : 'user',
        content: message.content
      }
    end
  end

  def track_usage(result)
    agent_metrics.create!(
      metric_type: 'message_processed',
      value: 1,
      metadata: {
        provider: result[:provider],
        model: result[:model],
        tokens_used: result[:usage]&.dig(:total_tokens),
        response_length: result[:content]&.length
      }
    )
  end

  def calculate_success_rate
    # This would be based on customer satisfaction or resolution metrics
    # For now, return a placeholder
    85.0
  end

  def find_most_used_capability
    # Analyze conversation content to find most used capability
    # This would require more sophisticated analysis
    capabilities.first
  end
end
