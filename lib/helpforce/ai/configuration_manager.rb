module Helpforce
  module Ai
    class ConfigurationManager
      class << self
        def setup_ai_providers!
          create_config_entries
          Rails.logger.info("HelpForce AI providers configuration completed")
        end

        def provider_status
          {
            openai: {
              configured: openai_configured?,
              api_key_present: openai_api_key.present?,
              model: openai_model,
              available_models: openai_configured? ? get_openai_models : []
            },
            claude: {
              configured: claude_configured?,
              api_key_present: claude_api_key.present?,
              model: claude_model,
              available_models: claude_configured? ? get_claude_models : []
            },
            gemini: {
              configured: gemini_configured?,
              api_key_present: gemini_api_key.present?,
              model: gemini_model,
              available_models: gemini_configured? ? get_gemini_models : []
            }
          }
        end

        def configure_provider(provider_name, api_key:, model: nil)
          case provider_name.to_s
          when 'openai'
            set_config('CAPTAIN_OPEN_AI_API_KEY', api_key)
            set_config('CAPTAIN_OPEN_AI_MODEL', model) if model
          when 'claude'
            set_config('CAPTAIN_CLAUDE_API_KEY', api_key)
            set_config('CAPTAIN_CLAUDE_MODEL', model) if model
          when 'gemini'
            set_config('CAPTAIN_GEMINI_API_KEY', api_key)
            set_config('CAPTAIN_GEMINI_MODEL', model) if model
          else
            raise ArgumentError, "Unknown provider: #{provider_name}"
          end
        end

        def get_default_provider
          providers = ['openai', 'claude', 'gemini']
          providers.find { |provider| send("#{provider}_configured?") } || 'openai'
        end

        def test_provider_connection(provider_name)
          case provider_name.to_s
          when 'openai'
            test_openai_connection
          when 'claude'
            test_claude_connection
          when 'gemini'
            test_gemini_connection
          else
            { success: false, error: "Unknown provider: #{provider_name}" }
          end
        end

        private

        def create_config_entries
          configs = [
            # OpenAI configs (already exist)
            { name: 'CAPTAIN_OPEN_AI_API_KEY', value: ENV['OPENAI_API_KEY'] },
            { name: 'CAPTAIN_OPEN_AI_MODEL', value: 'gpt-4o-mini' },
            
            # Claude configs
            { name: 'CAPTAIN_CLAUDE_API_KEY', value: ENV['ANTHROPIC_API_KEY'] },
            { name: 'CAPTAIN_CLAUDE_MODEL', value: 'claude-3-5-sonnet-20241022' },
            
            # Gemini configs  
            { name: 'CAPTAIN_GEMINI_API_KEY', value: ENV['GOOGLE_AI_API_KEY'] },
            { name: 'CAPTAIN_GEMINI_MODEL', value: 'gemini-1.5-flash' },
            
            # HelpForce AI settings
            { name: 'HELPFORCE_DEFAULT_AI_PROVIDER', value: get_default_provider },
            { name: 'HELPFORCE_AI_FEATURES_ENABLED', value: 'true' },
            { name: 'HELPFORCE_AI_AUTO_CATEGORIZATION', value: 'true' },
            { name: 'HELPFORCE_AI_SENTIMENT_ANALYSIS', value: 'true' }
          ]

          configs.each do |config|
            existing = InstallationConfig.find_by(name: config[:name])
            if existing.nil? && config[:value].present?
              InstallationConfig.create!(
                name: config[:name],
                value: config[:value],
                config_type: 'text'
              )
              Rails.logger.info("Created InstallationConfig: #{config[:name]}")
            end
          end
        end

        def openai_configured?
          openai_api_key.present?
        end

        def claude_configured?
          claude_api_key.present?
        end

        def gemini_configured?
          gemini_api_key.present?
        end

        def openai_api_key
          get_config('CAPTAIN_OPEN_AI_API_KEY') || ENV['OPENAI_API_KEY']
        end

        def claude_api_key
          get_config('CAPTAIN_CLAUDE_API_KEY') || ENV['ANTHROPIC_API_KEY']
        end

        def gemini_api_key
          get_config('CAPTAIN_GEMINI_API_KEY') || ENV['GOOGLE_AI_API_KEY']
        end

        def openai_model
          get_config('CAPTAIN_OPEN_AI_MODEL') || 'gpt-4o-mini'
        end

        def claude_model
          get_config('CAPTAIN_CLAUDE_MODEL') || 'claude-3-5-sonnet-20241022'
        end

        def gemini_model
          get_config('CAPTAIN_GEMINI_MODEL') || 'gemini-1.5-flash'
        end

        def get_openai_models
          Helpforce::Ai::Providers::OpenaiProvider::MODELS.keys
        end

        def get_claude_models
          Helpforce::Ai::Providers::ClaudeProvider::MODELS.keys
        end

        def get_gemini_models
          Helpforce::Ai::Providers::GeminiProvider::MODELS.keys
        end

        def test_openai_connection
          return { success: false, error: "OpenAI not configured" } unless openai_configured?

          provider = Helpforce::Ai::Providers::OpenaiProvider.new(
            api_key: openai_api_key,
            model: openai_model
          )
          
          result = provider.text_completion("Hello", max_tokens: 5)
          { success: true, response: result[:content] }
        rescue => e
          { success: false, error: e.message }
        end

        def test_claude_connection
          return { success: false, error: "Claude not configured" } unless claude_configured?

          provider = Helpforce::Ai::Providers::ClaudeProvider.new(
            api_key: claude_api_key,
            model: claude_model
          )
          
          result = provider.text_completion("Hello", max_tokens: 5)
          { success: true, response: result[:content] }
        rescue => e
          { success: false, error: e.message }
        end

        def test_gemini_connection
          return { success: false, error: "Gemini not configured" } unless gemini_configured?

          provider = Helpforce::Ai::Providers::GeminiProvider.new(
            api_key: gemini_api_key,
            model: gemini_model
          )
          
          result = provider.text_completion("Hello", max_tokens: 5)
          { success: true, response: result[:content] }
        rescue => e
          { success: false, error: e.message }
        end

        def get_config(name)
          InstallationConfig.find_by(name: name)&.value
        end

        def set_config(name, value)
          config = InstallationConfig.find_or_initialize_by(name: name)
          config.value = value
          config.config_type = 'text'
          config.save!
        end
      end
    end
  end
end