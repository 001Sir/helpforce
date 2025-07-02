class Integrations::HelpforceAiService < Integrations::OpenaiBaseService
  # Override ALLOWED_EVENT_NAMES to include new AI operations
  ALLOWED_EVENT_NAMES = %w[
    rephrase summarize reply_suggestion fix_spelling_grammar shorten expand 
    make_friendly make_formal simplify sentiment_analysis categorize_conversation
    multi_model_chat translate_text extract_entities generate_faq
  ].freeze

  CACHEABLE_EVENTS = %w[summarize sentiment_analysis categorize_conversation].freeze

  def perform
    return nil unless valid_event_name?

    return value_from_cache if value_from_cache.present?

    # Use multi-model service instead of direct OpenAI
    response = process_with_multi_model_ai
    save_to_cache(response) if response.present?

    response
  end

  private

  def process_with_multi_model_ai
    ai_service = Helpforce::Ai::MultiModelService.new(account: hook.account)
    
    case event_name
    when 'rephrase'
      handle_rephrase(ai_service)
    when 'summarize'
      handle_summarize(ai_service)
    when 'reply_suggestion'
      handle_reply_suggestion(ai_service)
    when 'sentiment_analysis'
      handle_sentiment_analysis(ai_service)
    when 'categorize_conversation'
      handle_categorize_conversation(ai_service)
    when 'multi_model_chat'
      handle_multi_model_chat(ai_service)
    when 'translate_text'
      handle_translate_text(ai_service)
    when 'extract_entities'
      handle_extract_entities(ai_service)
    when 'generate_faq'
      handle_generate_faq(ai_service)
    else
      # Fallback to original OpenAI implementation for backwards compatibility
      fallback_to_openai
    end
  rescue Helpforce::Ai::ApiError => e
    Rails.logger.error("HelpForce AI API error: #{e.message}")
    { error: e.message }
  rescue => e
    Rails.logger.error("HelpForce AI service error: #{e.message}")
    { error: "AI service temporarily unavailable" }
  end

  def handle_rephrase(ai_service)
    text = event_data['content']
    style = event_data['style'] || 'professional'
    provider = event_data['provider']
    
    result = ai_service.rephrase_text(text, style: style, provider: provider)
    format_response(result)
  end

  def handle_summarize(ai_service)
    provider = event_data['provider']
    
    if conversation
      result = ai_service.summarize_conversation(conversation, provider: provider)
      format_response(result)
    else
      { error: "Conversation not found" }
    end
  end

  def handle_reply_suggestion(ai_service)
    provider = event_data['provider']
    context = event_data['context']
    
    if conversation
      result = ai_service.suggest_reply(conversation, context: context, provider: provider)
      format_response(result)
    else
      { error: "Conversation not found" }
    end
  end

  def handle_sentiment_analysis(ai_service)
    text = event_data['content']
    provider = event_data['provider']
    
    sentiment = ai_service.extract_sentiment(text, provider: provider)
    { sentiment: sentiment }
  end

  def handle_categorize_conversation(ai_service)
    provider = event_data['provider']
    categories = event_data['categories']
    
    if conversation
      category = ai_service.categorize_conversation(conversation, categories: categories, provider: provider)
      { category: category }
    else
      { error: "Conversation not found" }
    end
  end

  def handle_multi_model_chat(ai_service)
    messages = event_data['messages']
    provider = event_data['provider']
    model = event_data['model']
    options = event_data['options'] || {}
    
    result = ai_service.chat_completion(messages, provider: provider, model: model, **options.symbolize_keys)
    format_response(result)
  end

  def handle_translate_text(ai_service)
    text = event_data['content']
    target_language = event_data['target_language'] || 'English'
    provider = event_data['provider']
    
    prompt = "Translate the following text to #{target_language}. Return only the translated text:\n\n#{text}"
    result = ai_service.text_completion(prompt, provider: provider)
    format_response(result)
  end

  def handle_extract_entities(ai_service)
    text = event_data['content']
    provider = event_data['provider']
    
    prompt = "Extract important entities (names, companies, products, issues) from this text. Return as a JSON array:\n\n#{text}"
    result = ai_service.text_completion(prompt, provider: provider)
    
    begin
      entities = JSON.parse(result[:content])
      { entities: entities }
    rescue JSON::ParserError
      format_response(result)
    end
  end

  def handle_generate_faq(ai_service)
    conversation_ids = event_data['conversation_ids'] || []
    provider = event_data['provider']
    
    if conversation_ids.any?
      conversations = hook.account.conversations.where(id: conversation_ids)
      conversation_text = conversations.map { |conv| format_conversation_for_faq(conv) }.join("\n\n---\n\n")
      
      prompt = "Based on these customer support conversations, generate 5 FAQ items in JSON format with 'question' and 'answer' fields:\n\n#{conversation_text}"
      result = ai_service.text_completion(prompt, provider: provider)
      
      begin
        faqs = JSON.parse(result[:content])
        { faqs: faqs }
      rescue JSON::ParserError
        format_response(result)
      end
    else
      { error: "No conversations provided" }
    end
  end

  def fallback_to_openai
    # Use the original OpenAI implementation for backwards compatibility
    send("#{event_name}_message")
  end

  def format_response(ai_result)
    if ai_result.is_a?(Hash) && ai_result[:content]
      {
        message: ai_result[:content],
        provider: ai_result[:provider],
        model: ai_result[:model],
        usage: ai_result[:usage]
      }
    else
      { message: ai_result.to_s }
    end
  end

  def format_conversation_for_faq(conversation)
    messages = conversation.messages.order(:created_at).map do |message|
      sender = message.outgoing? ? "Agent" : "Customer"
      "#{sender}: #{message.content}"
    end.join("\n")
    
    "Conversation ##{conversation.display_id}:\n#{messages}"
  end

  def event_data
    @event_data ||= event['data'] || {}
  end

  # Backwards compatibility methods that delegate to original OpenAI service
  def rephrase_message
    make_api_call(rephrase_body.to_json)
  end

  def summarize_message
    make_api_call(summarize_body.to_json)
  end

  def reply_suggestion_message
    make_api_call(reply_suggestion_body.to_json)
  end

  def fix_spelling_grammar_message
    make_api_call(fix_spelling_grammar_body.to_json)
  end

  def shorten_message
    make_api_call(shorten_body.to_json)
  end

  def expand_message
    make_api_call(expand_body.to_json)
  end

  def make_friendly_message
    make_api_call(make_friendly_body.to_json)
  end

  def make_formal_message
    make_api_call(make_formal_body.to_json)
  end

  def simplify_message
    make_api_call(simplify_body.to_json)
  end

  # Simple body builders for backwards compatibility
  def rephrase_body
    {
      model: GPT_MODEL,
      messages: [
        { role: 'user', content: "Please rephrase: #{event_data['content']}" }
      ]
    }
  end

  def summarize_body
    return { error: "Conversation not found" } unless conversation
    
    {
      model: GPT_MODEL,
      messages: [
        { role: 'user', content: "Summarize this conversation: #{format_conversation_messages}" }
      ]
    }
  end

  def reply_suggestion_body
    return { error: "Conversation not found" } unless conversation
    
    {
      model: GPT_MODEL,
      messages: [
        { role: 'user', content: "Suggest a reply for: #{format_conversation_messages}" }
      ]
    }
  end

  def fix_spelling_grammar_body
    {
      model: GPT_MODEL,
      messages: [
        { role: 'user', content: "Fix spelling and grammar: #{event_data['content']}" }
      ]
    }
  end

  def shorten_body
    {
      model: GPT_MODEL,
      messages: [
        { role: 'user', content: "Make this shorter: #{event_data['content']}" }
      ]
    }
  end

  def expand_body
    {
      model: GPT_MODEL,
      messages: [
        { role: 'user', content: "Expand on this: #{event_data['content']}" }
      ]
    }
  end

  def make_friendly_body
    {
      model: GPT_MODEL,
      messages: [
        { role: 'user', content: "Make this more friendly: #{event_data['content']}" }
      ]
    }
  end

  def make_formal_body
    {
      model: GPT_MODEL,
      messages: [
        { role: 'user', content: "Make this more formal: #{event_data['content']}" }
      ]
    }
  end

  def simplify_body
    {
      model: GPT_MODEL,
      messages: [
        { role: 'user', content: "Simplify this: #{event_data['content']}" }
      ]
    }
  end

  def format_conversation_messages
    return "" unless conversation
    
    conversation.messages.order(:created_at).map do |message|
      sender = message.outgoing? ? "Agent" : "Customer"
      "#{sender}: #{message.content}"
    end.join("\n")
  end
end