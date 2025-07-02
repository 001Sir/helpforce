# == Schema Information
#
# Table name: conversation_agent_assignments
#
#  id                  :bigint           not null, primary key
#  active              :boolean          default(TRUE)
#  assigned_at         :datetime
#  assignment_metadata :json
#  assignment_reason   :text
#  auto_assigned       :boolean          default(FALSE)
#  confidence_score    :decimal(5, 2)
#  unassigned_at       :datetime
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  conversation_id     :bigint           not null
#  helpforce_agent_id  :bigint           not null
#
# Indexes
#
#  idx_on_conversation_id_active_3e513758fe                    (conversation_id,active)
#  idx_on_helpforce_agent_id_assigned_at_36635535bc            (helpforce_agent_id,assigned_at)
#  index_conversation_agent_assignments_on_auto_assigned       (auto_assigned)
#  index_conversation_agent_assignments_on_confidence_score    (confidence_score)
#  index_conversation_agent_assignments_on_conversation_id     (conversation_id)
#  index_conversation_agent_assignments_on_helpforce_agent_id  (helpforce_agent_id)
#
# Foreign Keys
#
#  fk_rails_...  (conversation_id => conversations.id)
#  fk_rails_...  (helpforce_agent_id => helpforce_agents.id)
#
class ConversationAgentAssignment < ApplicationRecord
  belongs_to :conversation
  belongs_to :helpforce_agent

  validates :assignment_reason, presence: true
  validates :confidence_score, presence: true, 
            numericality: { greater_than: 0, less_than_or_equal_to: 100 }

  scope :active, -> { where(active: true) }
  scope :auto_assigned, -> { where(auto_assigned: true) }
  scope :manual_assigned, -> { where(auto_assigned: false) }
  scope :recent, -> { order(assigned_at: :desc) }
  scope :by_confidence, ->(min_confidence) { where('confidence_score >= ?', min_confidence) }

  before_validation :set_defaults, on: :create
  after_create :deactivate_previous_assignments
  after_update :handle_status_changes

  def assignment_duration
    end_time = unassigned_at || Time.current
    return nil unless assigned_at
    
    end_time - assigned_at
  end

  def assignment_duration_formatted
    duration = assignment_duration
    return "N/A" unless duration
    
    hours = (duration / 1.hour).to_i
    minutes = ((duration % 1.hour) / 1.minute).to_i
    
    if hours > 0
      "#{hours}h #{minutes}m"
    else
      "#{minutes}m"
    end
  end

  def high_confidence?
    confidence_score >= 80
  end

  def medium_confidence?
    confidence_score >= 50 && confidence_score < 80
  end

  def low_confidence?
    confidence_score < 50
  end

  def unassign!(reason = nil)
    update!(
      active: false,
      unassigned_at: Time.current,
      assignment_metadata: assignment_metadata.merge(
        unassignment_reason: reason,
        unassigned_by: 'system'
      )
    )
  end

  def assignment_success_metrics
    return {} unless conversation.status == 'resolved'
    
    {
      resolution_time: conversation.updated_at - assigned_at,
      message_count: conversation.messages.where('created_at >= ?', assigned_at).count,
      customer_satisfaction: extract_satisfaction_score,
      agent_efficiency: calculate_agent_efficiency
    }
  end

  def self.routing_analytics(account, time_range = 7.days)
    assignments = joins(:helpforce_agent)
                    .where(helpforce_agents: { account: account })
                    .where(assigned_at: time_range.ago..Time.current)

    {
      total_assignments: assignments.count,
      auto_assignments: assignments.auto_assigned.count,
      manual_assignments: assignments.manual_assigned.count,
      average_confidence: assignments.average(:confidence_score)&.round(2),
      high_confidence_rate: (assignments.by_confidence(80).count.to_f / assignments.count * 100).round(2),
      most_assigned_agent: find_most_assigned_agent(assignments),
      routing_success_rate: calculate_routing_success_rate(assignments)
    }
  end

  def self.agent_workload_analysis(agent, time_range = 7.days)
    assignments = where(helpforce_agent: agent)
                    .where(assigned_at: time_range.ago..Time.current)

    {
      total_assignments: assignments.count,
      active_assignments: assignments.active.count,
      average_assignment_duration: assignments.average(:assignment_duration),
      confidence_distribution: {
        high: assignments.by_confidence(80).count,
        medium: assignments.where(confidence_score: 50..79).count,
        low: assignments.where('confidence_score < 50').count
      },
      auto_vs_manual: {
        auto: assignments.auto_assigned.count,
        manual: assignments.manual_assigned.count
      }
    }
  end

  private

  def set_defaults
    self.assigned_at ||= Time.current
    self.active = true if active.nil?
    self.assignment_metadata ||= {}
  end

  def deactivate_previous_assignments
    # Deactivate any other active assignments for this conversation
    ConversationAgentAssignment
      .where(conversation: conversation, active: true)
      .where.not(id: id)
      .update_all(
        active: false,
        unassigned_at: Time.current,
        updated_at: Time.current
      )
  end

  def handle_status_changes
    if saved_change_to_active? && !active?
      self.unassigned_at ||= Time.current
      save! if unassigned_at_changed?
    end
  end

  def extract_satisfaction_score
    # Look for CSAT responses or sentiment analysis
    csat_responses = conversation.csat_survey_responses.last
    return csat_responses&.rating if csat_responses
    
    # Fallback to basic sentiment analysis
    recent_messages = conversation.messages
                                .where('created_at >= ?', assigned_at)
                                .where(message_type: 'incoming')
                                .last(3)
    
    return nil if recent_messages.empty?
    
    content = recent_messages.map(&:content).join(' ').downcase
    
    if content.match?(/thank|thanks|great|good|helpful|satisfied|resolved/)
      4 # Positive
    elsif content.match?(/bad|terrible|unhelpful|frustrated|angry/)
      2 # Negative
    else
      3 # Neutral
    end
  end

  def calculate_agent_efficiency
    return nil unless conversation.status == 'resolved'
    
    agent_messages = conversation.messages
                                .where('created_at >= ?', assigned_at)
                                .where(message_type: 'outgoing')
                                .count
    
    customer_messages = conversation.messages
                                   .where('created_at >= ?', assigned_at)
                                   .where(message_type: 'incoming')
                                   .count
    
    return nil if customer_messages.zero?
    
    # Lower ratio means more efficient (fewer back-and-forth messages)
    (agent_messages.to_f / customer_messages).round(2)
  end

  def self.find_most_assigned_agent(assignments)
    agent_counts = assignments.group(:helpforce_agent_id).count
    return nil if agent_counts.empty?
    
    most_assigned_id = agent_counts.max_by { |_, count| count }.first
    HelpforceAgent.find(most_assigned_id).name
  end

  def self.calculate_routing_success_rate(assignments)
    return 0 if assignments.empty?
    
    resolved_assignments = assignments.joins(:conversation)
                                    .where(conversations: { status: 'resolved' })
    
    (resolved_assignments.count.to_f / assignments.count * 100).round(2)
  end
end
