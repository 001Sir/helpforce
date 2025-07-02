module Helpforce
  class RoutingService
    include Rails.application.routes.url_helpers

    attr_reader :account

    def initialize(account)
      @account = account
    end

    # Auto-route new conversations
    def route_new_conversation(conversation)
      return unless should_auto_route?(conversation)
      
      router = Helpforce::Routing::SmartConversationRouter.new(
        account: account,
        conversation: conversation
      )
      
      routing_result = router.route_conversation
      
      # Log routing decision
      log_routing_decision(conversation, routing_result)
      
      routing_result
    end

    # Get routing recommendations for existing conversation
    def get_routing_recommendations(conversation)
      router = Helpforce::Routing::SmartConversationRouter.new(
        account: account,
        conversation: conversation
      )
      
      router.analyze_and_route
    end

    # Manual agent assignment
    def assign_agent_to_conversation(conversation, agent, assigned_by_user = nil)
      # Deactivate existing assignments
      conversation.conversation_agent_assignments.active.each(&:unassign!)
      
      # Create new assignment
      assignment = ConversationAgentAssignment.create!(
        conversation: conversation,
        helpforce_agent: agent,
        assignment_reason: "Manually assigned by #{assigned_by_user&.name || 'system'}",
        confidence_score: 100.0,
        auto_assigned: false,
        assignment_metadata: {
          assigned_by_user_id: assigned_by_user&.id,
          assignment_type: 'manual'
        }
      )

      # Update conversation status
      conversation.update!(status: 'open') if conversation.status == 'pending'

      # Send notification to assigned agent if configured
      notify_agent_assignment(assignment) if should_notify_agent?(agent)

      assignment
    end

    # Reassign conversation to different agent
    def reassign_conversation(conversation, new_agent, reason = nil, reassigned_by_user = nil)
      current_assignment = conversation.conversation_agent_assignments.active.first
      
      # Unassign current agent
      if current_assignment
        current_assignment.unassign!("Reassigned to #{new_agent.name}: #{reason}")
      end

      # Assign to new agent
      assign_agent_to_conversation(conversation, new_agent, reassigned_by_user)
    end

    # Remove agent assignment (route to human)
    def unassign_agent(conversation, reason = nil, unassigned_by_user = nil)
      assignments = conversation.conversation_agent_assignments.active
      
      assignments.each do |assignment|
        assignment.unassign!(reason || "Unassigned by #{unassigned_by_user&.name || 'system'}")
      end

      # Update conversation to require human attention
      conversation.update!(
        status: 'open',
        custom_attributes: conversation.custom_attributes.merge(
          'requires_human_agent' => true,
          'ai_agent_unassigned_at' => Time.current.iso8601
        )
      )

      # Track unassignment metrics
      track_unassignment_metrics(conversation, reason)
    end

    # Get routing analytics for account
    def routing_analytics(time_range = 7.days)
      base_scope = ConversationAgentAssignment
                     .joins(:helpforce_agent)
                     .where(helpforce_agents: { account: account })
                     .where(created_at: time_range.ago..Time.current)

      {
        routing_overview: calculate_routing_overview(base_scope),
        agent_performance: calculate_agent_performance(base_scope),
        routing_trends: calculate_routing_trends(base_scope, time_range),
        success_metrics: calculate_success_metrics(base_scope)
      }
    end

    # Bulk routing operations
    def bulk_route_conversations(conversation_ids)
      conversations = account.conversations.where(id: conversation_ids)
      results = []

      conversations.find_each do |conversation|
        result = route_new_conversation(conversation)
        results << {
          conversation_id: conversation.id,
          routed: result[:routed],
          agent: result[:assigned_agent]&.name,
          confidence: result[:routing_confidence]
        }
      end

      results
    end

    # Find conversations that need routing attention
    def find_conversations_needing_routing
      {
        unassigned: account.conversations
                           .where(status: ['pending', 'open'])
                           .left_joins(:conversation_agent_assignments)
                           .where(conversation_agent_assignments: { id: nil })
                           .limit(50),
        
        low_confidence: account.conversations
                               .joins(:conversation_agent_assignments)
                               .where(conversation_agent_assignments: { 
                                 active: true, 
                                 confidence_score: 0..40 
                               })
                               .limit(20),
        
        long_unresolved: account.conversations
                                .joins(:conversation_agent_assignments)
                                .where(conversation_agent_assignments: { active: true })
                                .where('conversation_agent_assignments.assigned_at < ?', 24.hours.ago)
                                .where(status: 'open')
                                .limit(20)
      }
    end

    private

    def should_auto_route?(conversation)
      # Check if account has auto-routing enabled
      return false unless account.feature_enabled?(:ai_auto_routing)
      
      # Don't auto-route if already assigned
      return false if conversation.conversation_agent_assignments.active.exists?
      
      # Don't auto-route if conversation is too old
      return false if conversation.created_at < 1.hour.ago
      
      # Don't auto-route if customer explicitly asked for human
      return false if conversation_requests_human?(conversation)
      
      true
    end

    def conversation_requests_human?(conversation)
      content = conversation.messages
                           .where(message_type: 'incoming')
                           .pluck(:content)
                           .join(' ')
                           .downcase

      content.match?(/human|person|real agent|speak to someone|not a bot/)
    end

    def should_notify_agent?(agent)
      # For now, don't send notifications for AI agents
      # This could be expanded to notify human agents in hybrid scenarios
      false
    end

    def notify_agent_assignment(assignment)
      # Placeholder for agent notification logic
      # Could send email, Slack message, etc.
      Rails.logger.info("Agent #{assignment.helpforce_agent.name} assigned to conversation #{assignment.conversation.display_id}")
    end

    def log_routing_decision(conversation, routing_result)
      Rails.logger.info(
        "Routing decision for conversation #{conversation.display_id}: " \
        "routed=#{routing_result[:routed]}, " \
        "confidence=#{routing_result[:routing_confidence]}, " \
        "agent=#{routing_result[:assigned_agent]&.name}"
      )

      # Store routing logs for analytics
      create_routing_log(conversation, routing_result)
    end

    def create_routing_log(conversation, routing_result)
      AgentMetric.create!(
        helpforce_agent: routing_result[:assigned_agent],
        metric_type: 'routing_decision',
        value: routing_result[:routing_confidence],
        metadata: {
          conversation_id: conversation.id,
          routed: routing_result[:routed],
          categories: routing_result[:analysis][:categories],
          urgency: routing_result[:analysis][:urgency],
          routing_reasons: routing_result[:routing_reasons]
        }
      )
    rescue => e
      Rails.logger.error("Failed to create routing log: #{e.message}")
    end

    def track_unassignment_metrics(conversation, reason)
      # Track when AI agents are unassigned (indicates potential routing failure)
      account.helpforce_agents.each do |agent|
        AgentMetric.create!(
          helpforce_agent: agent,
          metric_type: 'unassignment_event',
          value: 1,
          metadata: {
            conversation_id: conversation.id,
            reason: reason,
            unassigned_at: Time.current.iso8601
          }
        )
      end
    rescue => e
      Rails.logger.error("Failed to track unassignment metrics: #{e.message}")
    end

    def calculate_routing_overview(scope)
      {
        total_assignments: scope.count,
        auto_assignments: scope.auto_assigned.count,
        manual_assignments: scope.manual_assigned.count,
        average_confidence: scope.average(:confidence_score)&.round(2) || 0,
        active_assignments: scope.active.count
      }
    end

    def calculate_agent_performance(scope)
      scope.joins(:helpforce_agent)
           .group('helpforce_agents.name')
           .group('helpforce_agents.id')
           .select(
             'helpforce_agents.name as agent_name',
             'helpforce_agents.id as agent_id',
             'COUNT(*) as total_assignments',
             'AVG(confidence_score) as avg_confidence',
             'COUNT(CASE WHEN active = true THEN 1 END) as active_assignments'
           )
           .order('total_assignments DESC')
           .limit(10)
    end

    def calculate_routing_trends(scope, time_range)
      # Daily routing counts over the time range
      days = (time_range.to_i / 1.day).ceil
      
      (0...days).map do |days_ago|
        date = days_ago.days.ago.to_date
        day_scope = scope.where(created_at: date.beginning_of_day..date.end_of_day)
        
        {
          date: date,
          total_assignments: day_scope.count,
          auto_assignments: day_scope.auto_assigned.count,
          avg_confidence: day_scope.average(:confidence_score)&.round(2) || 0
        }
      end.reverse
    end

    def calculate_success_metrics(scope)
      resolved_conversations = scope.joins(:conversation)
                                   .where(conversations: { status: 'resolved' })
      
      {
        resolution_rate: (resolved_conversations.count.to_f / scope.count * 100).round(2),
        avg_resolution_time: calculate_avg_resolution_time(resolved_conversations),
        high_confidence_success_rate: calculate_high_confidence_success(scope)
      }
    end

    def calculate_avg_resolution_time(resolved_scope)
      times = resolved_scope.joins(:conversation)
                           .where.not(conversations: { resolved_at: nil })
                           .pluck('conversations.resolved_at - conversation_agent_assignments.assigned_at')
      
      return 0 if times.empty?
      
      avg_seconds = times.map(&:to_f).sum / times.length
      (avg_seconds / 1.hour).round(2) # Convert to hours
    end

    def calculate_high_confidence_success(scope)
      high_confidence = scope.where('confidence_score >= 80')
      high_confidence_resolved = high_confidence.joins(:conversation)
                                               .where(conversations: { status: 'resolved' })
      
      return 0 if high_confidence.count.zero?
      
      (high_confidence_resolved.count.to_f / high_confidence.count * 100).round(2)
    end
  end
end