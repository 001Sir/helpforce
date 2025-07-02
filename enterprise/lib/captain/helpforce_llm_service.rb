class Captain::HelpforceLlmService
  def initialize(config = {})
    @account = config[:account]
    @model = config[:model]
    @logger = Rails.logger
    
    # Initialize multi-model service first
    @ai_service = Helpforce::Ai::MultiModelService.new(account: @account)
    
    # Then determine provider
    @provider = config[:provider] || determine_best_provider
  end

  def call(messages, functions = [], **options)
    # Enhanced call method with multi-model support
    call_options = {
      provider: @provider,
      model: @model,
      tools: format_functions_for_provider(functions),
      temperature: options[:temperature] || 0.7,
      max_tokens: options[:max_tokens]
    }.compact

    # Add response format for JSON if needed
    if requires_json_response?(messages, functions)
      call_options = add_json_response_format(call_options)
    end

    response = @ai_service.chat_completion(messages, **call_options)
    handle_response(response, functions.any?)
  rescue => e
    handle_error(e)
  end

  def call_with_provider(messages, provider:, model: nil, functions: [], **options)
    # Allow explicit provider override
    original_provider = @provider
    original_model = @model
    
    @provider = provider
    @model = model if model
    
    result = call(messages, functions, **options)
    
    # Restore original settings
    @provider = original_provider
    @model = original_model
    
    result
  end

  def available_providers
    @ai_service.available_providers
  end

  def provider_info
    {
      current_provider: @provider,
      current_model: @model,
      available_providers: available_providers,
      provider_models: available_providers.map { |p| [p, @ai_service.get_provider_models(p)] }.to_h
    }
  end

  # Backwards compatibility with original LlmService interface
  def self.create_from_config(config)
    new(config)
  end

  private

  def determine_best_provider
    # Smart provider selection based on availability and capabilities
    available = @ai_service.available_providers
    
    # Prefer Claude for complex reasoning, OpenAI for general use, Gemini for speed
    preference_order = ['claude', 'openai', 'gemini']
    
    preferred = preference_order.find { |p| available.include?(p) }
    preferred || available.first || 'openai'
  end

  def requires_json_response?(messages, functions)
    # Check if we need JSON response format
    last_message = messages.is_a?(Array) ? messages.last : messages
    content = last_message.is_a?(Hash) ? last_message[:content] : last_message.to_s
    
    # Look for JSON request indicators
    content.downcase.include?('json') || 
    content.include?('response_format') ||
    functions.any?
  end

  def add_json_response_format(options)
    case @provider
    when 'openai'
      options[:response_format] = { type: 'json_object' }
    when 'claude'
      # Claude doesn't have explicit JSON response format, but we can add instruction
      options[:system_message] = "Please respond with valid JSON format."
    when 'gemini'
      # Gemini also doesn't have explicit JSON format, add instruction
      options[:system_message] = "Please respond with valid JSON format."
    end
    
    options
  end

  def format_functions_for_provider(functions)
    return [] if functions.empty?
    
    case @provider
    when 'openai'
      # OpenAI format (already correct)
      functions
    when 'claude'
      # Convert to Claude tools format
      functions.map { |func| convert_openai_function_to_claude(func) }
    when 'gemini'
      # Convert to Gemini tools format  
      functions.map { |func| convert_openai_function_to_gemini(func) }
    else
      functions
    end
  end

  def convert_openai_function_to_claude(function)
    {
      name: function[:function][:name],
      description: function[:function][:description],
      input_schema: function[:function][:parameters]
    }
  end

  def convert_openai_function_to_gemini(function)
    {
      functionDeclarations: [
        {
          name: function[:function][:name],
          description: function[:function][:description],
          parameters: function[:function][:parameters]
        }
      ]
    }
  end

  def handle_response(response, has_functions)
    # Handle different response formats from different providers
    if has_functions && response[:raw_response]
      handle_tool_calls(response)
    else
      handle_direct_response(response)
    end
  end

  def handle_tool_calls(response)
    # Extract tool calls from provider-specific response format
    raw = response[:raw_response]
    
    case @provider
    when 'openai'
      tool_calls = raw.dig('choices', 0, 'message', 'tool_calls')
      if tool_calls&.any?
        {
          tool_call: tool_calls.first,
          output: nil,
          stop: false,
          provider: @provider
        }
      else
        handle_direct_response(response)
      end
    when 'claude'
      content = raw.dig('content', 0)
      if content && content['type'] == 'tool_use'
        {
          tool_call: {
            function: {
              name: content['name'],
              arguments: content['input'].to_json
            }
          },
          output: nil,
          stop: false,
          provider: @provider
        }
      else
        handle_direct_response(response)
      end
    else
      handle_direct_response(response)
    end
  end

  def handle_direct_response(response)
    content = response[:content]
    
    # Try to parse as JSON first
    begin
      parsed = JSON.parse(content)
      {
        output: parsed['result'] || parsed['thought_process'] || parsed['response'] || content,
        stop: parsed['stop'] || false,
        provider: @provider,
        model: response[:model]
      }
    rescue JSON::ParserError
      # Fallback to plain text response
      {
        output: content,
        stop: false,
        provider: @provider,
        model: response[:model]
      }
    end
  end

  def handle_error(error)
    @logger.error("HelpForce LLM call failed: #{error.message}")
    @logger.error(error.backtrace.join("\n"))

    case error
    when Helpforce::Ai::ApiAuthenticationError
      { output: 'Authentication error. Please check API credentials.', stop: true, error: 'auth_error' }
    when Helpforce::Ai::ApiRateLimitError
      { output: 'Rate limit exceeded. Please try again later.', stop: false, error: 'rate_limit' }
    else
      { output: 'AI service temporarily unavailable. Please try again.', stop: false, error: 'service_error' }
    end
  end
end