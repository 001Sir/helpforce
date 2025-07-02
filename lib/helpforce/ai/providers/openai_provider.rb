module Helpforce
  module Ai
    module Providers
      class OpenaiProvider < BaseProvider
        API_URL = 'https://api.openai.com/v1/chat/completions'.freeze
        
        MODELS = {
          'gpt-4o' => { max_tokens: 128_000, supports_vision: true, supports_tools: true },
          'gpt-4o-mini' => { max_tokens: 128_000, supports_vision: true, supports_tools: true },
          'gpt-4-turbo' => { max_tokens: 128_000, supports_vision: true, supports_tools: true },
          'gpt-4' => { max_tokens: 8_192, supports_tools: true },
          'gpt-3.5-turbo' => { max_tokens: 16_385, supports_tools: true }
        }.freeze

        def provider_name
          'openai'
        end

        def default_model
          'gpt-4o-mini'
        end

        def available_models
          MODELS.keys
        end

        def max_tokens
          MODELS[@model][:max_tokens]
        end

        def supports_tools?
          MODELS[@model][:supports_tools] || false
        end

        def supports_vision?
          MODELS[@model][:supports_vision] || false
        end

        def chat_completion(messages, **options)
          body = build_request_body(messages, options)
          response = make_standard_request(API_URL, headers, body.to_json)
          normalize_response(JSON.parse(response.body))
        end

        def streaming_chat_completion(messages, **options, &block)
          body = build_request_body(messages, options.merge(stream: true))
          # For now, fall back to non-streaming. Can implement true streaming later
          chat_completion(messages, **options.except(:stream))
        end

        def text_completion(prompt, **options)
          messages = [{ role: 'user', content: prompt }]
          chat_completion(messages, **options)
        end

        private

        def headers
          {
            'Content-Type' => 'application/json',
            'Authorization' => "Bearer #{api_key}"
          }
        end

        def build_request_body(messages, options = {})
          {
            model: @model,
            messages: format_messages(messages),
            temperature: options[:temperature] || 0.7,
            max_tokens: options[:max_tokens],
            stream: options[:stream] || false,
            tools: options[:tools],
            tool_choice: options[:tool_choice]
          }.compact
        end

        def format_messages(messages)
          case messages
          when String
            [{ role: 'user', content: messages }]
          when Array
            messages.map do |msg|
              case msg
              when String
                { role: 'user', content: msg }
              when Hash
                msg
              else
                raise ArgumentError, "Invalid message format: #{msg.class}"
              end
            end
          else
            raise ArgumentError, "Messages must be a String or Array"
          end
        end

        def extract_content(response)
          response.dig('choices', 0, 'message', 'content')
        end

        def extract_usage(response)
          usage = response['usage']
          return nil unless usage

          {
            prompt_tokens: usage['prompt_tokens'],
            completion_tokens: usage['completion_tokens'],
            total_tokens: usage['total_tokens']
          }
        end
      end
    end
  end
end