module Helpforce
  module Marketplace
    class AgentRegistry
      # Built-in specialized AI agents for different support scenarios
      AGENTS = {
        'technical_support' => {
          name: 'Technical Support Specialist',
          description: 'Expert at diagnosing technical issues and providing step-by-step solutions',
          category: 'technical',
          capabilities: ['troubleshooting', 'debugging', 'system_analysis', 'solution_steps'],
          icon: '🔧',
          system_prompt: 'You are a technical support specialist.',
          conversation_starters: [
            "I'm having trouble with...",
            "The system is showing an error...",
            "How do I configure...",
            "The feature isn't working..."
          ],
          suggested_responses: {
            'error_analysis' => 'Let me help you analyze this error. Can you provide the exact error message?',
            'step_by_step' => 'I will walk you through this step by step to resolve the issue.',
            'system_check' => 'Let us run through some basic system checks first.'
          },
          pricing: 'free',
          provider_recommendations: ['openai', 'claude'],
          created_by: 'HelpForce',
          version: '1.0.0'
        },
        
        'billing_support' => {
          name: 'Billing & Payments Expert',
          description: 'Specialized in handling billing inquiries, payment issues, and subscription management',
          category: 'billing',
          capabilities: ['payment_processing', 'subscription_management', 'refund_handling', 'pricing_questions'],
          icon: '💳',
          system_prompt: 'You are a billing and payments expert.',
          conversation_starters: [
            "I have a question about my bill...",
            "My payment didn't go through...",
            "I need a refund for...",
            "Can you explain the charges..."
          ],
          suggested_responses: {
            'billing_inquiry' => 'I can help you with your billing question. Let me review your account details.',
            'payment_issue' => 'Let me help resolve this payment issue for you.',
            'refund_request' => 'I will process your refund request and explain the timeline.'
          },
          pricing: 'free',
          provider_recommendations: ['openai'],
          created_by: 'HelpForce',
          version: '1.0.0'
        },

        'sales_assistant' => {
          name: 'Sales Assistant Pro',
          description: 'Helps convert inquiries into sales with product knowledge and persuasive communication',
          category: 'sales',
          capabilities: ['product_recommendations', 'lead_qualification', 'objection_handling', 'upselling'],
          icon: '📈',
          system_prompt: 'You are a sales assistant focused on helping customers.',
          conversation_starters: [
            "I'm interested in your product...",
            "What's the difference between plans...",
            "Do you offer discounts...",
            "Can I schedule a demo..."
          ],
          suggested_responses: {
            'product_demo' => 'I would be happy to show you how our product can solve your specific needs.',
            'pricing_discussion' => 'Let me explain our pricing options and find the best fit for you.',
            'feature_comparison' => 'Here is how our features compare and which would work best for your use case.'
          },
          pricing: 'premium',
          provider_recommendations: ['claude', 'openai'],
          created_by: 'HelpForce',
          version: '1.0.0'
        },

        'onboarding_guide' => {
          name: 'Customer Onboarding Guide',
          description: 'Helps new customers get started quickly with personalized setup assistance',
          category: 'onboarding',
          capabilities: ['setup_guidance', 'feature_introduction', 'training_resources', 'progress_tracking'],
          icon: '🎯',
          system_prompt: 'You are a customer onboarding guide.',
          conversation_starters: [
            "I just signed up, where do I start?",
            "How do I set up my account?",
            "What features should I use first?",
            "I'm new to this type of software..."
          ],
          suggested_responses: {
            'welcome_message' => 'Welcome! I will help you get started with a personalized setup plan.',
            'next_steps' => 'Great progress! Here are the next steps to get you fully set up.',
            'feature_tutorial' => 'Let me show you how to use this key feature.'
          },
          pricing: 'free',
          provider_recommendations: ['openai', 'gemini'],
          created_by: 'HelpForce',
          version: '1.0.0'
        },

        'multilingual_support' => {
          name: 'Multilingual Support Agent',
          description: 'Provides customer support in multiple languages with cultural awareness',
          category: 'multilingual',
          capabilities: ['translation', 'cultural_adaptation', 'language_detection', 'localized_responses'],
          icon: '🌍',
          system_prompt: 'You are a multilingual support agent.',
          conversation_starters: [
            "Can you help me in Spanish?",
            "I need help in French",
            "Can you help me in German?",
            "Can you help me in English?"
          ],
          suggested_responses: {
            'language_switch' => 'Of course! I can help you in your preferred language.',
            'translation_offer' => 'I can translate this information for you.',
            'cultural_note' => 'Let me provide information relevant to your region.'
          },
          pricing: 'premium',
          provider_recommendations: ['claude', 'gemini'],
          created_by: 'HelpForce',
          version: '1.0.0'
        },

        'escalation_manager' => {
          name: 'Escalation Manager',
          description: 'Handles complex issues and manages escalations to appropriate human agents',
          category: 'management',
          capabilities: ['issue_assessment', 'priority_routing', 'escalation_management', 'handoff_preparation'],
          icon: '⚡',
          system_prompt: 'You are an escalation manager.',
          conversation_starters: [
            "This is urgent and needs immediate attention",
            "I have tried everything and nothing works",
            "I need to speak with a manager",
            "This issue is affecting my business"
          ],
          suggested_responses: {
            'urgent_assessment' => 'I understand this is urgent. Let me assess the situation and get you the right help.',
            'escalation_preparation' => 'I am preparing your case for escalation to ensure quick resolution.',
            'priority_handling' => 'This requires priority attention. I am connecting you with our specialist team.'
          },
          pricing: 'premium',
          provider_recommendations: ['claude', 'openai'],
          created_by: 'HelpForce',
          version: '1.0.0'
        }
      }.freeze

      class << self
        def all_agents
          AGENTS
        end

        def get_agent(agent_id)
          AGENTS[agent_id.to_s]
        end

        def agents_by_category(category)
          AGENTS.select { |_, agent| agent[:category] == category }
        end

        def free_agents
          AGENTS.select { |_, agent| agent[:pricing] == 'free' }
        end

        def premium_agents
          AGENTS.select { |_, agent| agent[:pricing] == 'premium' }
        end

        def search_agents(query)
          query = query.downcase
          AGENTS.select do |_, agent|
            agent[:name].downcase.include?(query) ||
            agent[:description].downcase.include?(query) ||
            agent[:capabilities].any? { |cap| cap.include?(query) }
          end
        end

        def agent_categories
          AGENTS.values.map { |agent| agent[:category] }.uniq
        end

        def recommended_agents_for_conversation(conversation)
          # Analyze conversation to recommend appropriate agents
          content = extract_conversation_content(conversation)
          
          recommendations = []
          
          # Technical keywords
          if content.match?(/error|bug|not working|broken|issue|problem|troubleshoot/i)
            recommendations << 'technical_support'
          end
          
          # Billing keywords
          if content.match?(/bill|payment|charge|refund|subscription|pricing|invoice/i)
            recommendations << 'billing_support'
          end
          
          # Sales keywords
          if content.match?(/buy|purchase|demo|trial|pricing|upgrade|features|product/i)
            recommendations << 'sales_assistant'
          end
          
          # Onboarding keywords
          if content.match?(/new|start|setup|how to|tutorial|guide|first time/i)
            recommendations << 'onboarding_guide'
          end
          
          # Urgency keywords
          if content.match?(/urgent|emergency|critical|asap|immediately|manager|escalate/i)
            recommendations << 'escalation_manager'
          end
          
          # Language detection
          if content.match?(/[^\x00-\x7F]/) # Non-ASCII characters indicate potential non-English
            recommendations << 'multilingual_support'
          end
          
          recommendations.uniq
        end

        private

        def extract_conversation_content(conversation)
          conversation.messages.last(5).map(&:content).join(' ')
        end
      end
    end
  end
end