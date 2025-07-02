module Helpforce
  module Ai
    class BaseProvider
      attr_reader :api_key, :model, :options

      def initialize(api_key:, model: nil, **options)
        @api_key = api_key
        @model = model || default_model
        @options = options
        validate_configuration!
      end

      # Abstract methods that must be implemented by providers
      def chat_completion(messages, **options)
        raise NotImplementedError, "#{self.class} must implement #chat_completion"
      end

      def streaming_chat_completion(messages, **options, &block)
        raise NotImplementedError, "#{self.class} must implement #streaming_chat_completion"
      end

      def text_completion(prompt, **options)
        raise NotImplementedError, "#{self.class} must implement #text_completion"
      end

      def provider_name
        raise NotImplementedError, "#{self.class} must implement #provider_name"
      end

      def default_model
        raise NotImplementedError, "#{self.class} must implement #default_model"
      end

      def available_models
        raise NotImplementedError, "#{self.class} must implement #available_models"
      end

      def max_tokens
        raise NotImplementedError, "#{self.class} must implement #max_tokens"
      end

      # Common functionality
      def supports_streaming?
        respond_to?(:streaming_chat_completion)
      end

      def supports_tools?
        false
      end

      def supports_vision?
        false
      end

      def token_limit
        max_tokens
      end

      # Normalize response format across providers
      def normalize_response(response)
        {
          content: extract_content(response),
          usage: extract_usage(response),
          model: @model,
          provider: provider_name,
          raw_response: response
        }
      end

      private

      def validate_configuration!
        raise ArgumentError, "API key is required" if api_key.blank?
        raise ArgumentError, "Invalid model: #{model}" unless available_models.include?(model)
      end

      def extract_content(response)
        raise NotImplementedError, "#{self.class} must implement #extract_content"
      end

      def extract_usage(response)
        raise NotImplementedError, "#{self.class} must implement #extract_usage"
      end

      def make_request(url, headers, body, stream: false, &block)
        if stream && block_given?
          make_streaming_request(url, headers, body, &block)
        else
          make_standard_request(url, headers, body)
        end
      end

      def make_standard_request(url, headers, body)
        Rails.logger.info("AI API request to #{provider_name}: #{body}")
        response = HTTParty.post(url, headers: headers, body: body)
        Rails.logger.info("AI API response from #{provider_name}: #{response.body}")

        unless response.success?
          handle_api_error(response)
        end

        response
      end

      def make_streaming_request(url, headers, body, &block)
        # Implementation for streaming requests
        # This would need to be implemented per provider
        raise NotImplementedError, "Streaming not implemented for #{provider_name}"
      end

      def handle_api_error(response)
        error_message = extract_error_message(response)
        Rails.logger.error("AI API error from #{provider_name}: #{error_message}")
        
        case response.code
        when 401
          raise ApiAuthenticationError, "Invalid API key for #{provider_name}"
        when 429
          raise ApiRateLimitError, "Rate limit exceeded for #{provider_name}"
        when 400
          raise ApiBadRequestError, "Bad request to #{provider_name}: #{error_message}"
        else
          raise ApiError, "API error from #{provider_name}: #{error_message}"
        end
      end

      def extract_error_message(response)
        return response.parsed_response.dig('error', 'message') if response.parsed_response.is_a?(Hash)
        "HTTP #{response.code}: #{response.message}"
      end
    end

    # Custom exceptions for better error handling
    class ApiError < StandardError; end
    class ApiAuthenticationError < ApiError; end
    class ApiRateLimitError < ApiError; end
    class ApiBadRequestError < ApiError; end
  end
end