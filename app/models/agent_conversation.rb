# == Schema Information
#
# Table name: agent_conversations
#
#  id                 :bigint           not null, primary key
#  ai_model           :string
#  ai_provider        :string
#  confidence_score   :decimal(5, 4)
#  feedback           :text
#  message_content    :text
#  metadata           :json
#  response_content   :text
#  response_time      :decimal(8, 3)
#  tokens_used        :integer
#  was_helpful        :boolean
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  conversation_id    :bigint           not null
#  helpforce_agent_id :bigint           not null
#
# Indexes
#
#  index_agent_conversations_on_ai_provider                        (ai_provider)
#  index_agent_conversations_on_conversation_id                    (conversation_id)
#  index_agent_conversations_on_conversation_id_and_created_at     (conversation_id,created_at)
#  index_agent_conversations_on_helpforce_agent_id                 (helpforce_agent_id)
#  index_agent_conversations_on_helpforce_agent_id_and_created_at  (helpforce_agent_id,created_at)
#  index_agent_conversations_on_response_time                      (response_time)
#
# Foreign Keys
#
#  fk_rails_...  (conversation_id => conversations.id)
#  fk_rails_...  (helpforce_agent_id => helpforce_agents.id)
#
class AgentConversation < ApplicationRecord
  belongs_to :helpforce_agent
  belongs_to :conversation

  validates :ai_provider, inclusion: { in: %w[openai claude gemini] }
  validates :message_content, presence: true
  validates :response_content, presence: true

  scope :successful, -> { where(was_helpful: true) }
  scope :by_provider, ->(provider) { where(ai_provider: provider) }
  scope :recent, -> { order(created_at: :desc) }
  scope :by_timeframe, ->(start_date, end_date) { where(created_at: start_date..end_date) }

  def duration_seconds
    response_time&.to_f
  end

  def successful?
    was_helpful == true
  end

  def usage_summary
    {
      provider: ai_provider,
      model: ai_model,
      tokens: tokens_used,
      duration: duration_seconds,
      confidence: confidence_score&.to_f
    }
  end

  def performance_metrics
    {
      response_time: duration_seconds,
      token_efficiency: tokens_used&.to_f / (response_content&.length || 1),
      confidence: confidence_score&.to_f || 0.0,
      success: successful?
    }
  end
end
