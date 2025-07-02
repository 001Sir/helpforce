require_relative 'conversation_analyzer'

module Helpforce
  module Routing
    class SmartConversationRouter
      include Rails.application.routes.url_helpers

      attr_reader :account, :conversation

      def initialize(account:, conversation:)
        @account = account
        @conversation = conversation
      end

      # Main routing method - determines best agent for conversation
      def route_conversation(force: false)
        routing_result = analyze_and_route
        
        if force || routing_result[:should_route]
          execute_routing(routing_result, force_route: force)
        else
          routing_result
        end
      end

      # Analyze conversation and determine routing recommendation
      def analyze_and_route
        analysis = ConversationAnalyzer.new(conversation).analyze
        
        {
          conversation_id: conversation.id,
          analysis: analysis,
          recommended_agents: find_matching_agents(analysis),
          routing_confidence: calculate_routing_confidence(analysis),
          should_route: should_auto_route?(analysis),
          routing_reasons: generate_routing_reasons(analysis),
          fallback_options: generate_fallback_options(analysis)
        }
      end

      # Execute the routing to assign agent to conversation
      def execute_routing(routing_result, force_route: false)
        return routing_result unless force_route || routing_result[:should_route]
        return routing_result if routing_result[:recommended_agents].empty?

        best_agent = routing_result[:recommended_agents].first
        
        begin
          # Create agent assignment
          assignment = ConversationAgentAssignment.create!(
            conversation: conversation,
            helpforce_agent: best_agent[:agent],
            assignment_reason: routing_result[:routing_reasons].join(', '),
            confidence_score: routing_result[:routing_confidence],
            auto_assigned: true
          )

          # Update conversation status if needed
          if conversation.status == 'pending'
            conversation.update!(status: 'open')
          end

          # Send initial agent response if configured
          if best_agent[:agent].auto_respond?
            send_initial_agent_response(best_agent[:agent])
          end

          # Track routing metrics
          track_routing_metrics(routing_result, assignment)

          routing_result.merge(
            routed: true,
            assigned_agent: best_agent[:agent],
            assignment_id: assignment.id
          )

        rescue => e
          Rails.logger.error("Smart routing failed: #{e.message}")
          routing_result.merge(
            routed: false,
            error: e.message
          )
        end
      end

      # Find agents that match conversation analysis
      def find_matching_agents(analysis)
        available_agents = account.helpforce_agents.active.includes(:agent_conversations)
        
        agent_scores = available_agents.map do |agent|
          score = calculate_agent_match_score(agent, analysis)
          next if score[:total_score] < minimum_match_threshold
          
          {
            agent: agent,
            score: score[:total_score],
            score_breakdown: score,
            match_reasons: score[:reasons]
          }
        end.compact

        # Sort by score and filter by availability
        agent_scores
          .sort_by { |result| -result[:score] }
          .select { |result| agent_available?(result[:agent]) }
          .first(3) # Top 3 matches
      end

      # Calculate how well an agent matches conversation analysis
      def calculate_agent_match_score(agent, analysis)
        score_components = {
          category_match: calculate_category_match(agent, analysis),
          capability_match: calculate_capability_match(agent, analysis),
          priority_match: calculate_priority_match(agent, analysis),
          language_match: calculate_language_match(agent, analysis),
          performance_bonus: calculate_performance_bonus(agent),
          availability_factor: calculate_availability_factor(agent)
        }

        total_score = score_components.values.sum
        reasons = generate_match_reasons(score_components)

        {
          total_score: total_score,
          reasons: reasons,
          **score_components
        }
      end

      private

      # Conversation analysis for routing decisions
      class ConversationAnalyzer
        attr_reader :conversation

        def initialize(conversation)
          @conversation = conversation
        end

        def analyze
          content = extract_conversation_content
          
          {
            content: content,
            categories: detect_categories(content),
            urgency: detect_urgency(content),
            language: detect_language(content),
            sentiment: detect_sentiment(content),
            customer_type: determine_customer_type,
            complexity: assess_complexity(content),
            keywords: extract_keywords(content)
          }
        end

        private

        def extract_conversation_content
          conversation.messages
                     .where(message_type: 'incoming')
                     .order(:created_at)
                     .pluck(:content)
                     .join(' ')
        end

        def detect_categories(content)
          categories = []
          
          # Technical support indicators
          if content.match?(/error|bug|not working|broken|issue|problem|troubleshoot|crash|freeze/i)
            categories << 'technical'
          end
          
          # Billing indicators
          if content.match?(/bill|payment|charge|refund|subscription|pricing|invoice|money|cost/i)
            categories << 'billing'
          end
          
          # Sales indicators
          if content.match?(/buy|purchase|demo|trial|pricing|upgrade|features|product|quote|sales/i)
            categories << 'sales'
          end
          
          # Onboarding indicators
          if content.match?(/new|start|setup|how to|tutorial|guide|first time|getting started/i)
            categories << 'onboarding'
          end
          
          # Escalation indicators
          if content.match?(/manager|supervisor|escalate|urgent|emergency|complaint|unsatisfied/i)
            categories << 'management'
          end
          
          categories.uniq
        end

        def detect_urgency(content)
          urgent_keywords = /urgent|emergency|critical|asap|immediately|now|help|stuck|down|broken/i
          
          if content.match?(urgent_keywords)
            conversation.messages.where(message_type: 'incoming').count > 3 ? 'critical' : 'high'
          elsif conversation.created_at < 1.hour.ago
            'medium'
          else
            'low'
          end
        end

        def detect_language(content)
          # Simple language detection based on character patterns
          return 'es' if content.match?(/[ñáéíóúü]/i)
          return 'fr' if content.match?(/[àâäéèêëïîôùûüÿç]/i)
          return 'de' if content.match?(/[äöüß]/i)
          return 'pt' if content.match?(/[ãõç]/i)
          
          'en' # Default to English
        end

        def detect_sentiment(content)
          negative_keywords = /angry|frustrated|terrible|awful|hate|worst|horrible|disappointed/i
          positive_keywords = /great|awesome|love|perfect|excellent|amazing|wonderful|satisfied/i
          
          if content.match?(negative_keywords)
            'negative'
          elsif content.match?(positive_keywords)
            'positive'
          else
            'neutral'
          end
        end

        def determine_customer_type
          # Determine if new vs existing customer
          if conversation.contact.conversations.count <= 1
            'new'
          elsif conversation.contact.conversations.count > 10
            'vip'
          else
            'existing'
          end
        end

        def assess_complexity(content)
          word_count = content.split.length
          technical_terms = content.scan(/api|database|server|configuration|integration|deployment/i).length
          
          if word_count > 200 || technical_terms > 3
            'high'
          elsif word_count > 50 || technical_terms > 0
            'medium'
          else
            'low'
          end
        end

        def extract_keywords(content)
          # Extract meaningful keywords for matching
          content.downcase
                 .scan(/\b\w{4,}\b/)
                 .reject { |word| common_words.include?(word) }
                 .tally
                 .sort_by { |_, count| -count }
                 .first(10)
                 .to_h
        end

        def common_words
          %w[that this with have been from they were said each which their time will about would there could other after first well]
        end
      end

      # Score calculation methods
      def calculate_category_match(agent, analysis)
        return 0 if analysis[:categories].empty?
        
        agent_categories = [agent.category] + (agent.capabilities || [])
        matches = (analysis[:categories] & agent_categories).length
        
        matches > 0 ? (matches.to_f / analysis[:categories].length) * 40 : 0
      end

      def calculate_capability_match(agent, analysis)
        return 20 if analysis[:keywords].empty?
        
        agent_keywords = (agent.capabilities || []) + agent.name.downcase.split
        keyword_matches = analysis[:keywords].keys.count { |keyword| 
          agent_keywords.any? { |ak| ak.include?(keyword) || keyword.include?(ak) }
        }
        
        keyword_matches > 0 ? (keyword_matches.to_f / analysis[:keywords].length) * 25 : 0
      end

      def calculate_priority_match(agent, analysis)
        case analysis[:urgency]
        when 'critical'
          agent.agent_id == 'escalation_manager' ? 30 : 10
        when 'high'
          agent.agent_id.in?(['escalation_manager', 'technical_support']) ? 20 : 15
        when 'medium'
          15
        else
          10
        end
      end

      def calculate_language_match(agent, analysis)
        return 15 if analysis[:language] == 'en'
        
        if agent.agent_id == 'multilingual_support'
          25
        elsif agent.capabilities&.include?('translation')
          15
        else
          5
        end
      end

      def calculate_performance_bonus(agent)
        performance = agent.performance_summary
        success_rate = performance[:success_rate] || 70
        
        case success_rate
        when 90..100
          15
        when 80..89
          10
        when 70..79
          5
        else
          0
        end
      end

      def calculate_availability_factor(agent)
        current_conversations = agent.agent_conversations
                                    .joins(:conversation)
                                    .where(conversations: { status: 'open' })
                                    .count
        
        case current_conversations
        when 0..2
          10
        when 3..5
          5
        else
          0
        end
      end

      def agent_available?(agent)
        # Check if agent is not overloaded
        active_conversations = agent.agent_conversations
                                   .joins(:conversation)
                                   .where(conversations: { status: 'open' })
                                   .count
        
        active_conversations < 10 # Max 10 concurrent conversations per agent
      end

      def calculate_routing_confidence(analysis)
        confidence = 50 # Base confidence
        
        confidence += 20 if analysis[:categories].any?
        confidence += 15 if analysis[:urgency] != 'low'
        confidence += 10 if analysis[:keywords].any?
        confidence += 5 if analysis[:sentiment] == 'negative'
        
        [confidence, 100].min
      end

      def should_auto_route?(analysis)
        # Auto-route if confidence is high and clear category match
        return false if analysis[:categories].empty?
        return true if analysis[:urgency] == 'critical'
        return true if analysis[:categories].length == 1 && analysis[:complexity] != 'high'
        
        false
      end

      def generate_routing_reasons(analysis)
        reasons = []
        
        reasons << "Detected #{analysis[:categories].join(', ')} categories" if analysis[:categories].any?
        reasons << "#{analysis[:urgency].capitalize} priority conversation" if analysis[:urgency] != 'low'
        reasons << "#{analysis[:sentiment].capitalize} customer sentiment" if analysis[:sentiment] != 'neutral'
        reasons << "#{analysis[:customer_type].capitalize} customer type" if analysis[:customer_type] != 'existing'
        
        reasons
      end

      def generate_fallback_options(analysis)
        {
          human_agent: "Route to human agent if AI routing fails",
          general_support: "Assign to general support queue",
          escalation: "Escalate to supervisor if high priority"
        }
      end

      def generate_match_reasons(score_components)
        reasons = []
        
        reasons << "Strong category match" if score_components[:category_match] > 20
        reasons << "High capability alignment" if score_components[:capability_match] > 15
        reasons << "Priority level match" if score_components[:priority_match] > 15
        reasons << "Language compatibility" if score_components[:language_match] > 15
        reasons << "Excellent performance record" if score_components[:performance_bonus] > 10
        reasons << "Agent available" if score_components[:availability_factor] > 5
        
        reasons
      end

      def minimum_match_threshold
        30 # Minimum score required for agent matching
      end

      def send_initial_agent_response(agent)
        # Send automated greeting from the assigned agent
        suggested_responses = agent.suggested_responses
        greeting = suggested_responses['greeting'] || 
                  suggested_responses.values.first ||
                  "Hello! I'm #{agent.name} and I'll be helping you today. How can I assist you?"

        conversation.messages.create!(
          account: account,
          content: greeting,
          message_type: 'outgoing',
          inbox: conversation.inbox,
          sender: account.users.first, # Use first admin as sender
          source_id: agent.id
        )
      end

      def track_routing_metrics(routing_result, assignment)
        # Track routing success metrics
        AgentMetric.create!(
          helpforce_agent: assignment.helpforce_agent,
          metric_type: 'conversation_completed', 
          value: 1,
          metadata: {
            routing_type: 'auto_routing',
            confidence_score: routing_result[:routing_confidence],
            categories: routing_result[:analysis][:categories],
            urgency: routing_result[:analysis][:urgency]
          }
        )
      end
    end
  end
end