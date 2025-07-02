# == Schema Information
#
# Table name: agent_metrics
#
#  id                 :bigint           not null, primary key
#  metadata           :json
#  metric_date        :date
#  metric_type        :string           not null
#  recorded_at        :datetime
#  value              :decimal(10, 4)
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  helpforce_agent_id :bigint           not null
#
# Indexes
#
#  index_agent_metrics_on_agent_type_date                     (helpforce_agent_id,metric_type,metric_date)
#  index_agent_metrics_on_helpforce_agent_id                  (helpforce_agent_id)
#  index_agent_metrics_on_helpforce_agent_id_and_recorded_at  (helpforce_agent_id,recorded_at)
#  index_agent_metrics_on_metric_type                         (metric_type)
#
# Foreign Keys
#
#  fk_rails_...  (helpforce_agent_id => helpforce_agents.id)
#
class AgentMetric < ApplicationRecord
  belongs_to :helpforce_agent

  validates :metric_type, presence: true
  validates :value, presence: true, numericality: true

  METRIC_TYPES = %w[
    message_processed
    response_time
    token_usage
    success_rate
    conversation_completed
    escalation_triggered
    user_satisfaction
    daily_active_conversations
    weekly_performance
  ].freeze

  validates :metric_type, inclusion: { in: METRIC_TYPES }

  scope :by_type, ->(type) { where(metric_type: type) }
  scope :for_date, ->(date) { where(metric_date: date) }
  scope :for_period, ->(start_date, end_date) { where(metric_date: start_date..end_date) }
  scope :recent, -> { order(recorded_at: :desc) }

  before_validation :set_metric_date, on: :create

  def self.aggregate_by_type(agent, metric_type, start_date, end_date)
    where(helpforce_agent: agent, metric_type: metric_type)
      .for_period(start_date, end_date)
      .sum(:value)
  end

  def self.average_by_type(agent, metric_type, start_date, end_date)
    where(helpforce_agent: agent, metric_type: metric_type)
      .for_period(start_date, end_date)
      .average(:value)
  end

  def self.daily_summary(agent, date = Date.current)
    metrics = where(helpforce_agent: agent, metric_date: date)
    
    {
      date: date,
      total_messages: metrics.by_type('message_processed').sum(:value),
      avg_response_time: metrics.by_type('response_time').average(:value),
      total_tokens: metrics.by_type('token_usage').sum(:value),
      conversations_completed: metrics.by_type('conversation_completed').sum(:value),
      success_rate: metrics.by_type('success_rate').average(:value) || 0
    }
  end

  def formatted_value
    case metric_type
    when 'response_time'
      "#{value.to_f.round(2)}s"
    when 'success_rate'
      "#{(value.to_f * 100).round(1)}%"
    when 'token_usage', 'message_processed', 'conversation_completed'
      value.to_i.to_s
    else
      value.to_s
    end
  end

  private

  def set_metric_date
    self.metric_date ||= Date.current
    self.recorded_at ||= Time.current
  end
end
