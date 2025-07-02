module Helpforce
  module Ai
    class ProviderFactory
      PROVIDERS = {
        'openai' => 'Helpforce::Ai::Providers::OpenaiProvider',
        'claude' => 'Helpforce::Ai::Providers::ClaudeProvider', 
        'gemini' => 'Helpforce::Ai::Providers::GeminiProvider'
      }.freeze

      def self.create_provider(provider_name, **options)
        provider_class = PROVIDERS[provider_name.to_s.downcase]
        raise ArgumentError, "Unsupported AI provider: #{provider_name}" unless provider_class

        provider_class.constantize.new(**options)
      end

      def self.available_providers
        PROVIDERS.keys
      end

      def self.default_provider
        'openai'
      end
    end
  end
end