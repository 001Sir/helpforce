#!/bin/bash

# HelpForce Rebranding Script
# This script transforms Chatwoot into HelpForce

echo "🚀 Starting HelpForce rebranding process..."

# 1. Update package.json
echo "📦 Updating package.json..."
sed -i '' 's/"@chatwoot\/chatwoot"/"@helpforce\/helpforce"/g' package.json
sed -i '' 's/"version": "4.3.0"/"version": "1.0.0"/g' package.json

# 2. Update main application files
echo "🔧 Updating main application references..."

# Update application.rb
sed -i '' 's/module Chatwoot/module HelpForce/g' config/application.rb
sed -i '' 's/Chatwoot::/HelpForce::/g' config/application.rb

# Update database configuration
sed -i '' 's/chatwoot/helpforce/g' config/database.yml

# Update environment files
if [ -f .env.example ]; then
    sed -i '' 's/chatwoot/helpforce/g' .env.example
    sed -i '' 's/Chatwoot/HelpForce/g' .env.example
fi

# 3. Update Ruby files
echo "💎 Updating Ruby files..."
find app lib config -name "*.rb" -type f -exec sed -i '' 's/module Chatwoot/module HelpForce/g' {} \;
find app lib config -name "*.rb" -type f -exec sed -i '' 's/class Chatwoot/class HelpForce/g' {} \;
find app lib config -name "*.rb" -type f -exec sed -i '' 's/Chatwoot::/HelpForce::/g' {} \;

# 4. Update Vue.js and JavaScript files
echo "🖥️  Updating frontend files..."
find app/javascript -name "*.vue" -type f -exec sed -i '' 's/Chatwoot/HelpForce/g' {} \;
find app/javascript -name "*.js" -type f -exec sed -i '' 's/Chatwoot/HelpForce/g' {} \;

# 5. Update HTML and ERB templates
echo "📄 Updating templates..."
find app/views -name "*.erb" -type f -exec sed -i '' 's/Chatwoot/HelpForce/g' {} \;

# 6. Update localization files
echo "🌐 Updating localization..."
if [ -f config/locales/en.yml ]; then
    sed -i '' 's/Chatwoot/HelpForce/g' config/locales/en.yml
fi

if [ -f app/javascript/dashboard/i18n/locale/en/index.js ]; then
    sed -i '' 's/Chatwoot/HelpForce/g' app/javascript/dashboard/i18n/locale/en/index.js
fi

# 7. Update Docker and deployment files
echo "🐳 Updating deployment files..."
sed -i '' 's/chatwoot/helpforce/g' docker-compose.yaml
sed -i '' 's/chatwoot/helpforce/g' docker-compose.production.yaml
sed -i '' 's/chatwoot/helpforce/g' Dockerfile || true

# 8. Update README and documentation
echo "📚 Updating documentation..."
cat > README.md << 'EOF'
# HelpForce

The AI-powered customer support platform built on open-source foundations.

HelpForce combines the power of modern customer support with advanced AI capabilities to help businesses deliver exceptional customer experiences.

## Key Features

- 🤖 **AI-Powered Response Suggestions** - Generate contextual responses instantly
- 💬 **Omnichannel Support** - Email, chat, social media, all in one place  
- 📊 **Intelligent Analytics** - Understand customer sentiment and team performance
- 🔀 **Smart Routing** - AI categorizes and routes tickets automatically
- 🚀 **Built for Scale** - Handle thousands of conversations effortlessly

## Quick Start

```bash
# Clone the repository
git clone https://github.com/your-org/helpforce.git
cd helpforce

# Install dependencies
bundle install && pnpm install

# Setup database
rails db:setup

# Start the application
pnpm dev
```

## Tech Stack

- **Backend**: Ruby on Rails 7.0
- **Frontend**: Vue.js 3 + Tailwind CSS
- **Database**: PostgreSQL
- **Cache**: Redis
- **AI**: OpenAI GPT-4 + Custom Models

## License

MIT License - See LICENSE file for details.

---

Built with ❤️ by the HelpForce team
EOF

# 9. Create initial AI service structure
echo "🧠 Creating AI service structure..."
mkdir -p app/services/ai
mkdir -p app/models/ai_response

# Create base AI service
cat > app/services/ai/base_service.rb << 'EOF'
# frozen_string_literal: true

module AI
  class BaseService
    include Rails.application.routes.url_helpers

    private

    def openai_client
      @openai_client ||= OpenAI::Client.new(access_token: ENV['OPENAI_API_KEY'])
    end

    def redis_client
      @redis_client ||= Redis.current
    end
  end
end
EOF

# Create response generator service
cat > app/services/ai/response_generator.rb << 'EOF'
# frozen_string_literal: true

module AI
  class ResponseGenerator < BaseService
    def initialize(conversation)
      @conversation = conversation
    end

    def generate_suggestions(count: 3)
      return [] unless valid_conversation?

      cache_key = "ai_suggestions:#{@conversation.id}:#{@conversation.updated_at.to_i}"
      
      cached_suggestions = redis_client.get(cache_key)
      return JSON.parse(cached_suggestions) if cached_suggestions

      suggestions = generate_fresh_suggestions(count)
      redis_client.setex(cache_key, 300, suggestions.to_json) # Cache for 5 minutes
      
      suggestions
    end

    private

    def valid_conversation?
      @conversation&.messages&.any?
    end

    def generate_fresh_suggestions(count)
      context = build_conversation_context
      prompt = build_response_prompt(context)

      response = openai_client.completions(
        parameters: {
          model: "gpt-4",
          prompt: prompt,
          max_tokens: 150,
          temperature: 0.7,
          n: count
        }
      )

      parse_suggestions(response)
    rescue StandardError => e
      Rails.logger.error "AI Response Generation failed: #{e.message}"
      []
    end

    def build_conversation_context
      recent_messages = @conversation.messages.recent.limit(10)
      
      recent_messages.map do |message|
        role = message.message_type == 'incoming' ? 'Customer' : 'Agent'
        "#{role}: #{message.content}"
      end.join("\n")
    end

    def build_response_prompt(context)
      <<~PROMPT
        You are a helpful customer support agent. Based on this conversation history, suggest professional and helpful responses.

        Conversation:
        #{context}

        Generate a helpful, professional response that addresses the customer's needs:
      PROMPT
    end

    def parse_suggestions(response)
      return [] unless response.dig("choices")

      response["choices"].map.with_index do |choice, index|
        {
          id: index + 1,
          text: choice.dig("text")&.strip,
          confidence: calculate_confidence(choice)
        }
      end.reject { |suggestion| suggestion[:text].blank? }
    end

    def calculate_confidence(choice)
      # Simple confidence calculation based on response length and coherence
      text = choice.dig("text")
      return 0 if text.blank?
      
      # Longer responses generally indicate higher confidence
      length_factor = [text.length / 100.0, 1.0].min
      
      # Responses that end with punctuation are more confident
      punctuation_factor = text.match?(/[.!?]$/) ? 1.0 : 0.8
      
      (length_factor * punctuation_factor * 100).round
    end
  end
end
EOF

# 10. Add OpenAI gem to Gemfile
echo "💎 Adding AI dependencies to Gemfile..."
echo "" >> Gemfile
echo "# AI and ML gems" >> Gemfile
echo "gem 'ruby-openai', '~> 7.0'" >> Gemfile
echo "gem 'redis', '~> 5.0'" >> Gemfile

# 11. Update git configuration
echo "🔧 Updating git configuration..."
git remote rename origin upstream 2>/dev/null || true

echo "✅ HelpForce rebranding complete!"
echo ""
echo "Next steps:"
echo "1. Run 'bundle install' to install new gems"
echo "2. Update your .env file with OPENAI_API_KEY"
echo "3. Run 'rails db:migrate' to ensure database is up to date"
echo "4. Start the development server with 'pnpm dev'"
echo ""
echo "🎉 Welcome to HelpForce!"
EOF