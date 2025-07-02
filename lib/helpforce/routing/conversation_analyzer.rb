module Helpforce
  module Routing
    class ConversationAnalyzer
      attr_reader :conversation

      def initialize(conversation)
        @conversation = conversation
      end

      def analyze
        {
          category: determine_category,
          sentiment: analyze_sentiment,
          complexity: determine_complexity,
          language: detect_language,
          urgency: determine_urgency,
          tags: extract_tags,
          key_phrases: extract_key_phrases,
          customer_profile: analyze_customer_profile
        }
      end

      private

      def determine_category
        content = get_conversation_content.downcase

        if content.match?(/technical|error|bug|crash|broken|doesn't work|problem|issue/)
          'technical'
        elsif content.match?(/billing|payment|charge|refund|invoice|subscription|price/)
          'billing'
        elsif content.match?(/onboard|setup|getting started|new|tutorial|how to/)
          'onboarding'
        elsif content.match?(/sales|pricing|plan|upgrade|enterprise|demo/)
          'sales'
        else
          'general'
        end
      end

      def analyze_sentiment
        content = get_conversation_content.downcase
        
        positive_words = %w[thanks thank amazing great excellent wonderful fantastic happy love]
        negative_words = %w[angry frustrated terrible awful bad horrible hate disappointed upset]
        
        positive_count = positive_words.count { |word| content.include?(word) }
        negative_count = negative_words.count { |word| content.include?(word) }
        
        if negative_count > positive_count
          'negative'
        elsif positive_count > negative_count
          'positive'
        else
          'neutral'
        end
      end

      def determine_complexity
        content = get_conversation_content
        message_count = conversation.messages.count
        
        # Factors for complexity
        technical_terms = content.scan(/API|integration|database|server|configuration|authentication/).length
        question_marks = content.count('?')
        
        complexity_score = (message_count * 0.3) + (technical_terms * 0.5) + (question_marks * 0.2)
        
        if complexity_score > 5
          'high'
        elsif complexity_score > 2
          'medium'
        else
          'low'
        end
      end

      def detect_language
        content = get_conversation_content
        
        # Simple language detection
        if content.match?(/[¿¡áéíóúñü]/i) || content.match?(/\b(hola|gracias|por favor|ayuda)\b/i)
          'spanish'
        elsif content.match?(/[àâäéèêëïîôûùüÿç]/i) || content.match?(/\b(bonjour|merci|s'il vous plaît)\b/i)
          'french'
        elsif content.match?(/[äöüß]/i) || content.match?(/\b(danke|bitte|hilfe)\b/i)
          'german'
        else
          'english'
        end
      end

      def determine_urgency
        content = get_conversation_content.downcase
        
        urgent_keywords = %w[urgent emergency asap immediately critical blocking down broken]
        
        if urgent_keywords.any? { |keyword| content.include?(keyword) }
          'high'
        elsif content.include?('soon') || content.include?('quickly')
          'medium'
        else
          'low'
        end
      end

      def extract_tags
        tags = []
        content = get_conversation_content.downcase
        
        # Product/feature mentions
        tags << 'api' if content.include?('api')
        tags << 'mobile' if content.match?(/mobile|app|ios|android/)
        tags << 'integration' if content.include?('integration')
        tags << 'security' if content.match?(/security|password|login|authentication/)
        
        tags
      end

      def extract_key_phrases
        content = get_conversation_content
        
        # Extract questions
        questions = content.scan(/[^.!?]*\?/).map(&:strip)
        
        # Extract error messages
        errors = content.scan(/"([^"]+)"/).flatten + content.scan(/'([^']+)'/).flatten
        
        {
          questions: questions.take(3),
          errors: errors.take(3)
        }
      end

      def analyze_customer_profile
        contact = conversation.contact
        
        {
          previous_conversations: contact.conversations.count,
          is_returning_customer: contact.conversations.count > 1,
          account_age: (Time.current - contact.created_at).to_i / 1.day,
          preferred_language: detect_language
        }
      end

      def get_conversation_content
        @conversation_content ||= conversation.messages
                                             .where(message_type: 'incoming')
                                             .order(created_at: :desc)
                                             .limit(10)
                                             .pluck(:content)
                                             .join(' ')
      end
    end
  end
end