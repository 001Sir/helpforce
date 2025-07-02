module Helpforce
  module Ai
    module Providers
      class ClaudeProvider < BaseProvider
        API_URL = 'https://api.anthropic.com/v1/messages'.freeze
        API_VERSION = '2023-06-01'.freeze
        
        MODELS = {
          'claude-3-5-sonnet-20241022' => { max_tokens: 200_000, supports_vision: true },
          'claude-3-5-haiku-20241022' => { max_tokens: 200_000, supports_vision: true },
          'claude-3-opus-20240229' => { max_tokens: 200_000, supports_vision: true },
          'claude-3-sonnet-20240229' => { max_tokens: 200_000, supports_vision: true },
          'claude-3-haiku-20240307' => { max_tokens: 200_000, supports_vision: true }
        }.freeze

        def provider_name
          'claude'
        end

        def default_model
          'claude-3-5-sonnet-20241022'
        end

        def available_models
          MODELS.keys
        end

        def max_tokens
          MODELS[@model][:max_tokens]
        end

        def supports_vision?
          MODELS[@model][:supports_vision] || false
        end

        def supports_tools?
          true # Claude supports tools/function calling
        end

        def chat_completion(messages, **options)
          body = build_request_body(messages, options)
          response = make_standard_request(API_URL, headers, body.to_json)
          normalize_response(JSON.parse(response.body))
        end

        def text_completion(prompt, **options)
          messages = [{ role: 'user', content: prompt }]
          chat_completion(messages, **options)
        end

        private

        def headers
          {
            'Content-Type' => 'application/json',
            'x-api-key' => api_key,
            'anthropic-version' => API_VERSION
          }
        end

        def build_request_body(messages, options = {})
          formatted_messages = format_messages_for_claude(messages)
          
          {
            model: @model,
            messages: formatted_messages[:messages],
            system: formatted_messages[:system],
            max_tokens: options[:max_tokens] || 4096,
            temperature: options[:temperature] || 0.7,
            tools: options[:tools]
          }.compact
        end

        def format_messages_for_claude(messages)
          formatted_messages = []
          system_message = nil

          case messages
          when String
            formatted_messages = [{ role: 'user', content: messages }]
          when Array
            messages.each do |msg|
              case msg
              when String
                formatted_messages << { role: 'user', content: msg }
              when Hash
                if msg[:role] == 'system'
                  system_message = msg[:content]
                else
                  formatted_messages << msg
                end
              end
            end
          end

          # Ensure alternating user/assistant pattern required by Claude
          formatted_messages = ensure_alternating_roles(formatted_messages)

          {
            messages: formatted_messages,
            system: system_message
          }
        end

        def ensure_alternating_roles(messages)
          # Claude requires strict user/assistant alternation
          result = []
          last_role = nil

          messages.each do |msg|
            role = msg[:role]
            
            if role == last_role
              # Merge consecutive messages from same role
              if result.last
                result.last[:content] = "#{result.last[:content]}\n\n#{msg[:content]}"
              end
            else
              result << msg
              last_role = role
            end
          end

          # Ensure we start with user message
          if result.first && result.first[:role] != 'user'
            result.unshift({ role: 'user', content: 'Hello' })
          end

          result
        end

        def extract_content(response)
          content = response.dig('content', 0)
          return nil unless content

          case content['type']
          when 'text'
            content['text']
          when 'tool_use'
            # Handle tool use responses
            content
          else
            nil
          end
        end

        def extract_usage(response)
          usage = response['usage']
          return nil unless usage

          {
            prompt_tokens: usage['input_tokens'],
            completion_tokens: usage['output_tokens'],
            total_tokens: usage['input_tokens'] + usage['output_tokens']
          }
        end
      end
    end
  end
end