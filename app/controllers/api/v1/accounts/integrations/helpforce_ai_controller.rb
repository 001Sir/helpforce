class Api::V1::Accounts::Integrations::HelpforceAiController < Api::V1::Accounts::BaseController
  before_action :check_authorization

  def index
    # Get status of all AI providers
    render json: {
      providers: Helpforce::Ai::ConfigurationManager.provider_status,
      default_provider: Helpforce::Ai::ConfigurationManager.get_default_provider,
      supported_operations: HelpforceAi::SUPPORTED_OPERATIONS,
      conversation_categories: HelpforceAi::CONVERSATION_CATEGORIES
    }
  end

  def configure_provider
    provider_name = params[:provider]
    api_key = params[:api_key]
    model = params[:model]

    unless HelpforceAi::SUPPORTED_PROVIDERS.include?(provider_name)
      return render json: { error: "Unsupported provider: #{provider_name}" }, status: :bad_request
    end

    if api_key.blank?
      return render json: { error: "API key is required" }, status: :bad_request
    end

    begin
      Helpforce::Ai::ConfigurationManager.configure_provider(
        provider_name,
        api_key: api_key,
        model: model
      )

      # Test the connection
      test_result = Helpforce::Ai::ConfigurationManager.test_provider_connection(provider_name)
      
      if test_result[:success]
        render json: {
          success: true,
          message: "#{provider_name.capitalize} configured successfully",
          test_response: test_result[:response]
        }
      else
        render json: {
          success: false,
          error: "Configuration saved but connection test failed: #{test_result[:error]}"
        }, status: :unprocessable_entity
      end
    rescue => e
      render json: { error: "Failed to configure provider: #{e.message}" }, status: :internal_server_error
    end
  end

  def test_provider
    provider_name = params[:provider]

    unless HelpforceAi::SUPPORTED_PROVIDERS.include?(provider_name)
      return render json: { error: "Unsupported provider: #{provider_name}" }, status: :bad_request
    end

    result = Helpforce::Ai::ConfigurationManager.test_provider_connection(provider_name)
    
    if result[:success]
      render json: { success: true, response: result[:response] }
    else
      render json: { success: false, error: result[:error] }, status: :unprocessable_entity
    end
  end

  def chat_completion
    messages = params[:messages]
    provider = params[:provider]
    model = params[:model]
    options = params[:options] || {}

    if messages.blank?
      return render json: { error: "Messages are required" }, status: :bad_request
    end

    begin
      ai_service = Helpforce::Ai::MultiModelService.new(account: Current.account)
      result = ai_service.chat_completion(
        messages,
        provider: provider,
        model: model,
        **options.symbolize_keys
      )

      render json: {
        success: true,
        content: result[:content],
        provider: result[:provider],
        model: result[:model],
        usage: result[:usage]
      }
    rescue => e
      render json: { error: "Chat completion failed: #{e.message}" }, status: :internal_server_error
    end
  end

  def rephrase_text
    text = params[:text]
    style = params[:style] || 'professional'
    provider = params[:provider]

    if text.blank?
      return render json: { error: "Text is required" }, status: :bad_request
    end

    unless HelpforceAi::REPHRASE_STYLES.include?(style)
      return render json: { error: "Invalid style. Supported: #{HelpforceAi::REPHRASE_STYLES.join(', ')}" }, status: :bad_request
    end

    begin
      ai_service = Helpforce::Ai::MultiModelService.new(account: Current.account)
      result = ai_service.rephrase_text(text, style: style, provider: provider)

      render json: {
        success: true,
        original_text: text,
        rephrased_text: result[:content],
        style: style,
        provider: result[:provider],
        model: result[:model]
      }
    rescue => e
      render json: { error: "Text rephrasing failed: #{e.message}" }, status: :internal_server_error
    end
  end

  def analyze_sentiment
    text = params[:text]
    provider = params[:provider]

    if text.blank?
      return render json: { error: "Text is required" }, status: :bad_request
    end

    begin
      ai_service = Helpforce::Ai::MultiModelService.new(account: Current.account)
      sentiment = ai_service.extract_sentiment(text, provider: provider)

      render json: {
        success: true,
        text: text,
        sentiment: sentiment,
        confidence: determine_sentiment_confidence(sentiment)
      }
    rescue => e
      render json: { error: "Sentiment analysis failed: #{e.message}" }, status: :internal_server_error
    end
  end

  def categorize_conversation
    conversation_id = params[:conversation_id]
    categories = params[:categories] || HelpforceAi::CONVERSATION_CATEGORIES
    provider = params[:provider]

    conversation = Current.account.conversations.find_by(id: conversation_id)
    unless conversation
      return render json: { error: "Conversation not found" }, status: :not_found
    end

    begin
      ai_service = Helpforce::Ai::MultiModelService.new(account: Current.account)
      category = ai_service.categorize_conversation(conversation, categories: categories, provider: provider)

      render json: {
        success: true,
        conversation_id: conversation.id,
        category: category,
        available_categories: categories
      }
    rescue => e
      render json: { error: "Conversation categorization failed: #{e.message}" }, status: :internal_server_error
    end
  end

  def bulk_operations
    operation = params[:operation]
    conversations = params[:conversation_ids] || []
    provider = params[:provider]
    options = params[:options] || {}

    unless HelpforceAi::SUPPORTED_OPERATIONS.include?(operation)
      return render json: { error: "Unsupported operation: #{operation}" }, status: :bad_request
    end

    if conversations.empty?
      return render json: { error: "Conversation IDs are required" }, status: :bad_request
    end

    begin
      ai_service = Helpforce::Ai::MultiModelService.new(account: Current.account)
      results = []

      conversations.each do |conv_id|
        conversation = Current.account.conversations.find_by(id: conv_id)
        next unless conversation

        case operation
        when 'summarize'
          result = ai_service.summarize_conversation(conversation, provider: provider)
          results << { conversation_id: conv_id, summary: result[:content] }
        when 'categorize'
          category = ai_service.categorize_conversation(conversation, provider: provider)
          results << { conversation_id: conv_id, category: category }
        when 'sentiment'
          # Analyze sentiment of the last customer message
          last_message = conversation.messages.where(message_type: 'incoming').last
          if last_message
            sentiment = ai_service.extract_sentiment(last_message.content, provider: provider)
            results << { conversation_id: conv_id, sentiment: sentiment }
          end
        end
      end

      render json: {
        success: true,
        operation: operation,
        results: results,
        processed_count: results.count
      }
    rescue => e
      render json: { error: "Bulk operation failed: #{e.message}" }, status: :internal_server_error
    end
  end

  private

  def check_authorization
    authorize(Current.account, :admin?)
  end

  def determine_sentiment_confidence(sentiment)
    # Simple confidence scoring based on sentiment clarity
    case sentiment
    when 'positive', 'negative'
      'high'
    when 'neutral'
      'medium'
    else
      'low'
    end
  end
end