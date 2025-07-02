module Helpforce
  module Ai
    class MultiModelService
      attr_reader :account, :user

      def initialize(account:, user: nil)
        @account = account
        @user = user
      end

      # Main interface for AI operations
      def chat_completion(messages, provider: nil, model: nil, **options)
        provider_instance = get_provider(provider, model)
        provider_instance.chat_completion(messages, **options)
      end

      def text_completion(prompt, provider: nil, model: nil, **options)
        provider_instance = get_provider(provider, model)
        provider_instance.text_completion(prompt, **options)
      end

      def streaming_chat_completion(messages, provider: nil, model: nil, **options, &block)
        provider_instance = get_provider(provider, model)
        if provider_instance.supports_streaming?
          provider_instance.streaming_chat_completion(messages, **options, &block)
        else
          # Fallback to regular chat completion
          result = provider_instance.chat_completion(messages, **options)
          yield result if block_given?
          result
        end
      end

      # AI operation helpers for common use cases
      def rephrase_text(text, style: 'professional', provider: nil)
        prompt = build_rephrase_prompt(text, style)
        text_completion(prompt, provider: provider)
      end

      def summarize_conversation(conversation, provider: nil)
        messages = format_conversation_for_ai(conversation)
        system_message = "Summarize this customer support conversation in 2-3 sentences, focusing on the main issue and resolution."
        
        full_messages = [
          { role: 'system', content: system_message },
          { role: 'user', content: messages }
        ]
        
        chat_completion(full_messages, provider: provider)
      end

      def suggest_reply(conversation, context: nil, provider: nil)
        messages = format_conversation_for_ai(conversation)
        system_prompt = build_reply_suggestion_prompt(context)
        
        full_messages = [
          { role: 'system', content: system_prompt },
          { role: 'user', content: "Based on this conversation, suggest a helpful reply:\n\n#{messages}" }
        ]
        
        chat_completion(full_messages, provider: provider)
      end

      def extract_sentiment(text, provider: nil)
        prompt = "Analyze the sentiment of this text and return only one word: positive, negative, or neutral.\n\nText: #{text}"
        result = text_completion(prompt, provider: provider)
        result[:content]&.strip&.downcase
      end

      def categorize_conversation(conversation, categories: nil, provider: nil)
        categories ||= ['technical_support', 'billing', 'general_inquiry', 'complaint', 'feature_request']
        messages = format_conversation_for_ai(conversation)
        
        prompt = "Categorize this conversation into one of these categories: #{categories.join(', ')}. Return only the category name.\n\nConversation:\n#{messages}"
        result = text_completion(prompt, provider: provider)
        result[:content]&.strip&.downcase
      end

      # Provider management
      def available_providers
        ProviderFactory.available_providers.select { |provider| provider_configured?(provider) }
      end

      def provider_configured?(provider_name)
        config = get_provider_config(provider_name)
        config[:api_key].present?
      end

      def get_provider_models(provider_name)
        return [] unless provider_configured?(provider_name)
        
        provider_instance = create_provider(provider_name)
        provider_instance.available_models
      end

      def get_default_provider
        # Return first configured provider, fallback to OpenAI
        available_providers.first || 'openai'
      end

      private

      def get_provider(provider_name = nil, model = nil)
        provider_name ||= get_default_provider
        provider_instance = create_provider(provider_name, model: model)
        
        unless provider_instance
          raise ArgumentError, "Provider #{provider_name} is not configured or available"
        end
        
        provider_instance
      end

      def create_provider(provider_name, model: nil)
        config = get_provider_config(provider_name)
        return nil unless config[:api_key].present?

        ProviderFactory.create_provider(
          provider_name,
          api_key: config[:api_key],
          model: model || config[:model]
        )
      rescue => e
        Rails.logger.error("Failed to create AI provider #{provider_name}: #{e.message}")
        nil
      end

      def get_provider_config(provider_name)
        case provider_name.to_s
        when 'openai'
          {
            api_key: get_config_value('CAPTAIN_OPEN_AI_API_KEY') || ENV['OPENAI_API_KEY'],
            model: get_config_value('CAPTAIN_OPEN_AI_MODEL')
          }
        when 'claude'
          {
            api_key: get_config_value('CAPTAIN_CLAUDE_API_KEY') || ENV['ANTHROPIC_API_KEY'],
            model: get_config_value('CAPTAIN_CLAUDE_MODEL')
          }
        when 'gemini'
          {
            api_key: get_config_value('CAPTAIN_GEMINI_API_KEY') || ENV['GOOGLE_AI_API_KEY'],
            model: get_config_value('CAPTAIN_GEMINI_MODEL')
          }
        else
          { api_key: nil, model: nil }
        end
      end

      def get_config_value(key)
        InstallationConfig.find_by(name: key)&.value
      end

      def build_rephrase_prompt(text, style)
        style_instructions = {
          'professional' => 'in a professional and courteous tone',
          'friendly' => 'in a warm and friendly tone',
          'formal' => 'in a formal business tone',
          'casual' => 'in a casual and conversational tone',
          'concise' => 'more concisely while keeping the key points',
          'detailed' => 'with more detail and explanation'
        }

        instruction = style_instructions[style] || 'in a clear and professional manner'
        "Please rephrase the following text #{instruction}. Return only the rephrased text without any additional commentary:\n\n#{text}"
      end

      def build_reply_suggestion_prompt(context)
        base_prompt = "You are a helpful customer support assistant. Based on the conversation history, suggest a professional and helpful reply that addresses the customer's needs."
        
        if context.present?
          base_prompt += "\n\nAdditional context: #{context}"
        end
        
        base_prompt += "\n\nProvide only the suggested reply text, without any prefixes or explanations."
        base_prompt
      end

      def format_conversation_for_ai(conversation)
        conversation.messages.order(:created_at).map do |message|
          sender = message.outgoing? ? "Agent" : "Customer"
          "#{sender}: #{message.content}"
        end.join("\n")
      end
    end
  end
end