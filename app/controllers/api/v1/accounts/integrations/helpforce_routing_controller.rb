class Api::V1::Accounts::Integrations::HelpforceRoutingController < Api::V1::Accounts::BaseController
  before_action :find_conversation, only: [:show, :route, :assign, :unassign, :reassign]
  before_action :find_agent, only: [:assign, :reassign]

  # GET /api/v1/accounts/{account_id}/helpforce_routing/analytics
  def analytics
    begin
      time_range = parse_time_range(params[:time_range])
      routing_service = Helpforce::RoutingService.new(Current.account)
      
      analytics_data = routing_service.routing_analytics(time_range)
      
      render json: {
        success: true,
        data: analytics_data,
        time_range: time_range_description(time_range)
      }
    rescue => e
      Rails.logger.error "Routing analytics error: #{e.message}"
      Rails.logger.error e.backtrace.first(5).join("\n")
      
      # Return empty analytics data structure
      render json: {
        success: true,
        data: {
          routing_overview: {
            total_assignments: 0,
            auto_assignments: 0,
            manual_assignments: 0,
            average_confidence: 0,
            active_assignments: 0
          },
          agent_performance: [],
          routing_trends: [],
          success_metrics: {
            resolution_rate: 0,
            avg_resolution_time: 0,
            high_confidence_success_rate: 0
          }
        },
        time_range: time_range_description(time_range),
        message: "No routing data available yet"
      }
    end
  end

  # GET /api/v1/accounts/{account_id}/helpforce_routing/conversations/{conversation_id}
  def show
    routing_service = Helpforce::RoutingService.new(Current.account)
    recommendations = routing_service.get_routing_recommendations(@conversation)
    
    current_assignment = @conversation.conversation_agent_assignments.active.first
    
    render json: {
      success: true,
      data: {
        conversation_id: @conversation.id,
        current_assignment: format_assignment(current_assignment),
        recommendations: recommendations,
        routing_history: format_routing_history(@conversation)
      }
    }
  end

  # POST /api/v1/accounts/{account_id}/helpforce_routing/conversations/{conversation_id}/route
  def route
    routing_service = Helpforce::RoutingService.new(Current.account)
    result = routing_service.route_new_conversation(@conversation)
    
    # If auto-routing didn't happen, force it for API endpoint
    if result.nil? || !result[:routed]
      router = Helpforce::Routing::SmartConversationRouter.new(
        account: Current.account,
        conversation: @conversation
      )
      result = router.route_conversation(force: true)
    end
    
    if result && result[:routed]
      render json: {
        success: true,
        message: "Conversation routed successfully",
        data: {
          assigned_agent: format_agent(result[:assigned_agent]),
          confidence: result[:routing_confidence],
          reasons: result[:routing_reasons]
        }
      }
    else
      render json: {
        success: false,
        message: "Could not auto-route conversation",
        data: {
          recommendations: result[:recommended_agents],
          reasons: result[:routing_reasons],
          fallback_options: result[:fallback_options]
        }
      }
    end
  end

  # POST /api/v1/accounts/{account_id}/helpforce_routing/conversations/{conversation_id}/assign
  def assign
    routing_service = Helpforce::RoutingService.new(Current.account)
    
    assignment = routing_service.assign_agent_to_conversation(
      @conversation, 
      @agent, 
      Current.user
    )
    
    render json: {
      success: true,
      message: "Agent assigned successfully",
      data: {
        assignment: format_assignment(assignment),
        agent: format_agent(@agent)
      }
    }
  rescue => e
    render json: {
      success: false,
      message: "Failed to assign agent: #{e.message}"
    }, status: :unprocessable_entity
  end

  # POST /api/v1/accounts/{account_id}/helpforce_routing/conversations/{conversation_id}/reassign
  def reassign
    routing_service = Helpforce::RoutingService.new(Current.account)
    reason = params[:reason] || "Reassigned by #{Current.user.name}"
    
    assignment = routing_service.reassign_conversation(
      @conversation,
      @agent,
      reason,
      Current.user
    )
    
    render json: {
      success: true,
      message: "Conversation reassigned successfully",
      data: {
        assignment: format_assignment(assignment),
        new_agent: format_agent(@agent),
        reason: reason
      }
    }
  rescue => e
    render json: {
      success: false,
      message: "Failed to reassign conversation: #{e.message}"
    }, status: :unprocessable_entity
  end

  # DELETE /api/v1/accounts/{account_id}/helpforce_routing/conversations/{conversation_id}/assign
  def unassign
    routing_service = Helpforce::RoutingService.new(Current.account)
    reason = params[:reason] || "Unassigned by #{Current.user.name}"
    
    routing_service.unassign_agent(@conversation, reason, Current.user)
    
    render json: {
      success: true,
      message: "Agent unassigned successfully",
      data: {
        conversation_id: @conversation.id,
        reason: reason,
        requires_human_agent: true
      }
    }
  rescue => e
    render json: {
      success: false,
      message: "Failed to unassign agent: #{e.message}"
    }, status: :unprocessable_entity
  end

  # GET /api/v1/accounts/{account_id}/helpforce_routing/needs_attention
  def needs_attention
    begin
      routing_service = Helpforce::RoutingService.new(Current.account)
      conversations = routing_service.find_conversations_needing_routing
      
      render json: {
        success: true,
        data: {
          unassigned: format_conversations(conversations[:unassigned]),
          low_confidence: format_conversations(conversations[:low_confidence]),
          long_unresolved: format_conversations(conversations[:long_unresolved]),
          summary: {
            total_needing_attention: conversations.values.map(&:count).sum,
            unassigned_count: conversations[:unassigned].count,
            low_confidence_count: conversations[:low_confidence].count,
            long_unresolved_count: conversations[:long_unresolved].count
          }
        }
      }
    rescue => e
      Rails.logger.error "Routing needs_attention error: #{e.message}"
      Rails.logger.error e.backtrace.first(5).join("\n")
      
      # Return empty structure
      render json: {
        success: true,
        data: {
          unassigned: [],
          low_confidence: [],
          long_unresolved: [],
          summary: {
            total_needing_attention: 0,
            unassigned_count: 0,
            low_confidence_count: 0,
            long_unresolved_count: 0
          }
        },
        message: "No conversations needing attention"
      }
    end
  end

  # POST /api/v1/accounts/{account_id}/helpforce_routing/bulk_route
  def bulk_route
    conversation_ids = params[:conversation_ids] || []
    
    if conversation_ids.empty?
      render json: {
        success: false,
        message: "No conversation IDs provided"
      }, status: :bad_request
      return
    end

    routing_service = Helpforce::RoutingService.new(Current.account)
    results = routing_service.bulk_route_conversations(conversation_ids)
    
    successful_routes = results.count { |r| r[:routed] }
    
    render json: {
      success: true,
      message: "Bulk routing completed",
      data: {
        total_processed: results.length,
        successful_routes: successful_routes,
        failed_routes: results.length - successful_routes,
        results: results
      }
    }
  end

  # GET /api/v1/accounts/{account_id}/helpforce_routing/agent_workload
  def agent_workload
    begin
      time_range = parse_time_range(params[:time_range])
      
      workload_data = Current.account.helpforce_agents.active.map do |agent|
        workload = ConversationAgentAssignment.agent_workload_analysis(agent, time_range)
        
        {
          agent_id: agent.id,
          agent_name: agent.name,
          agent_category: agent.category,
          **workload
        }
      end
      
      render json: {
        success: true,
        data: {
          agents: workload_data,
          time_range: time_range_description(time_range)
        }
      }
    rescue => e
      Rails.logger.error "Routing agent_workload error: #{e.message}"
      Rails.logger.error e.backtrace.first(5).join("\n")
      
      # Return agents with empty workload
      agents_data = Current.account.helpforce_agents.active.map do |agent|
        {
          agent_id: agent.id,
          agent_name: agent.name,
          agent_category: agent.category,
          active_conversations: 0,
          completed_today: 0,
          avg_handling_time: 0,
          satisfaction_score: 0
        }
      end
      
      render json: {
        success: true,
        data: {
          agents: agents_data,
          time_range: time_range_description(parse_time_range(params[:time_range]))
        },
        message: "No workload data available yet"
      }
    end
  end

  private

  def find_conversation
    @conversation = Current.account.conversations.find(params[:conversation_id])
  rescue ActiveRecord::RecordNotFound
    render json: {
      success: false,
      message: "Conversation not found"
    }, status: :not_found
  end

  def find_agent
    @agent = Current.account.helpforce_agents.find(params[:agent_id])
  rescue ActiveRecord::RecordNotFound
    render json: {
      success: false,
      message: "Agent not found"
    }, status: :not_found
  end

  def format_assignment(assignment)
    return nil unless assignment
    
    {
      id: assignment.id,
      agent: format_agent(assignment.helpforce_agent),
      confidence_score: assignment.confidence_score,
      assignment_reason: assignment.assignment_reason,
      auto_assigned: assignment.auto_assigned,
      assigned_at: assignment.assigned_at,
      duration: assignment.assignment_duration_formatted,
      active: assignment.active
    }
  end

  def format_agent(agent)
    return nil unless agent
    
    {
      id: agent.id,
      name: agent.name,
      agent_id: agent.agent_id,
      category: agent.category,
      icon: agent.icon,
      capabilities: agent.capabilities,
      is_premium: agent.is_premium?,
      status: agent.status
    }
  end

  def format_routing_history(conversation)
    conversation.conversation_agent_assignments
                .includes(:helpforce_agent)
                .order(assigned_at: :desc)
                .limit(10)
                .map { |assignment| format_assignment(assignment) }
  end

  def format_conversations(conversations)
    conversations.limit(50).map do |conversation|
      {
        id: conversation.id,
        display_id: conversation.display_id,
        status: conversation.status,
        created_at: conversation.created_at,
        updated_at: conversation.updated_at,
        message_count: conversation.messages.count,
        contact: {
          id: conversation.contact.id,
          name: conversation.contact.name,
          email: conversation.contact.email
        },
        current_assignment: format_assignment(
          conversation.conversation_agent_assignments.active.first
        ),
        last_message: conversation.messages.last&.content&.truncate(100)
      }
    end
  end

  def parse_time_range(range_param)
    case range_param
    when '1d', '1day'
      1.day
    when '3d', '3days'
      3.days
    when '1w', '1week'
      1.week
    when '2w', '2weeks'
      2.weeks
    when '1m', '1month'
      1.month
    else
      7.days # Default to 1 week
    end
  end

  def time_range_description(time_range)
    case time_range
    when 1.day
      "Last 24 hours"
    when 3.days
      "Last 3 days"
    when 1.week
      "Last week"
    when 2.weeks
      "Last 2 weeks"
    when 1.month
      "Last month"
    else
      "Last 7 days"
    end
  end
end