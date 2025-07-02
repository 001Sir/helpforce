module Helpforce
  module Ai
    module Providers
      class GeminiProvider < BaseProvider
        BASE_URL = 'https://generativelanguage.googleapis.com/v1beta/models'.freeze
        
        MODELS = {
          'gemini-1.5-pro' => { max_tokens: 2_000_000, supports_vision: true, supports_tools: true },
          'gemini-1.5-flash' => { max_tokens: 1_000_000, supports_vision: true, supports_tools: true },
          'gemini-1.0-pro' => { max_tokens: 32_000, supports_tools: true }
        }.freeze

        def provider_name
          'gemini'
        end

        def default_model
          'gemini-1.5-flash'
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
          MODELS[@model][:supports_tools] || false
        end

        def chat_completion(messages, **options)
          body = build_request_body(messages, options)
          url = "#{BASE_URL}/#{@model}:generateContent?key=#{api_key}"
          response = make_standard_request(url, headers, body.to_json)
          normalize_response(JSON.parse(response.body))
        end

        def text_completion(prompt, **options)
          messages = [{ role: 'user', content: prompt }]
          chat_completion(messages, **options)
        end

        private

        def headers
          {
            'Content-Type' => 'application/json'
          }
        end

        def build_request_body(messages, options = {})
          {
            contents: format_messages_for_gemini(messages),
            generationConfig: {
              temperature: options[:temperature] || 0.7,
              maxOutputTokens: options[:max_tokens] || 4096,
              topK: options[:top_k],
              topP: options[:top_p]
            }.compact,
            tools: format_tools(options[:tools])
          }.compact
        end

        def format_messages_for_gemini(messages)
          formatted_messages = []

          case messages
          when String
            formatted_messages = [{ role: 'user', parts: [{ text: messages }] }]
          when Array
            messages.each do |msg|
              case msg
              when String
                formatted_messages << { role: 'user', parts: [{ text: msg }] }
              when Hash
                role = convert_role_to_gemini(msg[:role])
                content = msg[:content]
                
                formatted_messages << {
                  role: role,
                  parts: [{ text: content }]
                }
              end
            end
          end

          # Gemini requires specific role alternation
          ensure_gemini_role_pattern(formatted_messages)
        end

        def convert_role_to_gemini(role)
          case role.to_s
          when 'user'
            'user'
          when 'assistant', 'system'
            'model'
          else
            'user'
          end
        end

        def ensure_gemini_role_pattern(messages)
          # Gemini alternates between 'user' and 'model'
          result = []
          
          messages.each_with_index do |msg, index|
            if index == 0 && msg[:role] != 'user'
              # First message must be from user
              result << { role: 'user', parts: [{ text: 'Hello' }] }
            end
            
            result << msg
          end

          result
        end

        def format_tools(tools)
          return nil if tools.blank?

          # Convert OpenAI-style tools to Gemini format
          tools.map do |tool|
            {
              functionDeclarations: [
                {
                  name: tool[:function][:name],
                  description: tool[:function][:description],
                  parameters: tool[:function][:parameters]
                }
              ]
            }
          end
        end

        def extract_content(response)
          candidate = response.dig('candidates', 0)
          return nil unless candidate

          parts = candidate.dig('content', 'parts')
          return nil unless parts&.any?

          # Get text from the first part
          parts.first['text']
        end

        def extract_usage(response)
          metadata = response['usageMetadata']
          return nil unless metadata

          {
            prompt_tokens: metadata['promptTokenCount'],
            completion_tokens: metadata['candidatesTokenCount'],
            total_tokens: metadata['totalTokenCount']
          }
        end
      end
    end
  end
end