# HelpForce AI Multi-Model Support Initializer

# Skip initialization during asset precompilation
unless ENV['RAILS_GROUPS'] == 'assets' || ENV['DATABASE_URL'].nil?
  Rails.application.config.after_initialize do
  # Load HelpForce AI modules
  require_relative '../../lib/helpforce/ai/base_provider'
  require_relative '../../lib/helpforce/ai/provider_factory'
  require_relative '../../lib/helpforce/ai/providers/openai_provider'
  require_relative '../../lib/helpforce/ai/providers/claude_provider'
  require_relative '../../lib/helpforce/ai/providers/gemini_provider'
  require_relative '../../lib/helpforce/ai/multi_model_service'
  require_relative '../../lib/helpforce/ai/configuration_manager'
  require_relative '../../lib/integrations/helpforce_ai_service'

  # Initialize AI provider configurations
  begin
    Helpforce::Ai::ConfigurationManager.setup_ai_providers!
    Rails.logger.info("✅ HelpForce AI multi-model support initialized")
    
    # Log available providers
    status = Helpforce::Ai::ConfigurationManager.provider_status
    status.each do |provider, config|
      if config[:configured]
        Rails.logger.info("✅ #{provider.to_s.upcase} configured with model: #{config[:model]}")
      else
        Rails.logger.info("⚠️  #{provider.to_s.upcase} not configured")
      end
    end
    
  rescue => e
    Rails.logger.error("❌ Failed to initialize HelpForce AI: #{e.message}")
    Rails.logger.error(e.backtrace.first(5).join("\n"))
  end
  end
end

# Add HelpForce AI constants
module HelpforceAi
  SUPPORTED_OPERATIONS = %w[
    rephrase summarize reply_suggestion sentiment_analysis 
    categorize_conversation multi_model_chat translate_text
    extract_entities generate_faq fix_spelling_grammar
    shorten expand make_friendly make_formal simplify
  ].freeze

  SUPPORTED_PROVIDERS = %w[openai claude gemini].freeze
  
  DEFAULT_PROVIDER = 'openai'.freeze
  
  CONVERSATION_CATEGORIES = %w[
    technical_support billing general_inquiry complaint 
    feature_request bug_report account_issue refund_request
    product_question integration_help
  ].freeze
  
  SENTIMENT_TYPES = %w[positive negative neutral].freeze
  
  REPHRASE_STYLES = %w[
    professional friendly formal casual concise detailed
  ].freeze
end