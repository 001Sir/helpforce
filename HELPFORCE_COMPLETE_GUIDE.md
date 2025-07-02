# HelpForce Complete Guide: Everything You Need to Know

## Table of Contents
1. [Overview](#overview)
2. [Architecture](#architecture)
3. [File Structure](#file-structure)
4. [Installation & Setup](#installation--setup)
5. [Core Features Detailed](#core-features-detailed)
6. [API Reference](#api-reference)
7. [UI Components Guide](#ui-components-guide)
8. [Database Schema](#database-schema)
9. [Configuration](#configuration)
10. [Testing & Demo Scripts](#testing--demo-scripts)
11. [Troubleshooting](#troubleshooting)
12. [Monetization Strategy](#monetization-strategy)

---

## Overview

HelpForce is an AI-powered enhancement layer built on top of Chatwoot (open-source customer support platform). It adds intelligent conversation routing, multi-model AI support, and an agent marketplace to transform basic chat support into an AI-driven powerhouse.

**Key Value Props:**
- 80% faster response times with AI agents
- 24/7 intelligent support coverage
- Automatic conversation routing based on ML analysis
- Multi-language support
- Deep analytics and insights

---

## Architecture

### High-Level Architecture
```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   Frontend      │────▶│   Rails API     │────▶│   AI Services   │
│   (Vue.js 3)    │     │   Controllers   │     │  (Multi-Model)  │
└─────────────────┘     └─────────────────┘     └─────────────────┘
         │                       │                        │
         ▼                       ▼                        ▼
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   Tailwind CSS  │     │   PostgreSQL    │     │   OpenAI/Claude │
│   Components    │     │   Database      │     │   /Gemini APIs  │
└─────────────────┘     └─────────────────┘     └─────────────────┘
```

### Request Flow
1. User interacts with Vue.js frontend
2. Frontend makes API calls to Rails backend
3. Controllers use service objects for business logic
4. Services interact with AI providers via factory pattern
5. Results stored in PostgreSQL and returned to frontend

---

## File Structure

### Backend Files (Ruby on Rails)

#### Controllers
```
app/controllers/api/v1/accounts/integrations/
├── helpforce_ai_controller.rb          # AI operations (sentiment, rephrase, chat)
├── helpforce_marketplace_controller.rb  # Agent marketplace management
└── helpforce_routing_controller.rb      # Smart routing operations
```

#### Models
```
app/models/
├── helpforce_agent.rb                   # AI agent definitions
├── conversation_agent_assignment.rb     # Routing history & assignments
└── agent_metric.rb                      # Performance metrics
```

#### Services
```
app/services/helpforce/
├── ai/
│   ├── multi_model_service.rb          # Main AI service (factory pattern)
│   ├── providers/
│   │   ├── base_provider.rb            # Abstract provider interface
│   │   ├── openai_provider.rb          # OpenAI implementation
│   │   ├── claude_provider.rb          # Claude implementation
│   │   └── gemini_provider.rb          # Gemini implementation
│   └── configuration_manager.rb        # AI provider configuration
├── routing_service.rb                  # Main routing orchestrator
└── marketplace_service.rb              # Agent marketplace logic

lib/helpforce/routing/
├── smart_conversation_router.rb        # ML-based routing algorithm
└── conversation_analyzer.rb            # Conversation analysis engine
```

#### Database Migrations
```
db/migrate/
├── 20240701000001_create_helpforce_agents.rb
├── 20240701000002_create_conversation_agent_assignments.rb
└── 20240701000003_create_agent_metrics.rb
```

### Frontend Files (Vue.js 3)

#### Main Components
```
app/javascript/dashboard/routes/dashboard/helpcenter/pages/helpforce/
├── Index.vue                           # Main HelpForce dashboard
├── components/
│   ├── HelpforceDashboard.vue         # Dashboard overview
│   ├── AgentMarketplace.vue           # Browse & install agents
│   ├── RoutingDashboard.vue           # Routing analytics
│   ├── AiSettings.vue                 # AI provider configuration
│   ├── AgentCard.vue                  # Individual agent display
│   ├── RoutingMetrics.vue             # Routing performance metrics
│   └── ConversationRouter.vue         # Manual routing interface
```

### Configuration Files
```
config/
├── routes.rb                           # Added HelpForce routes
├── features.yml                        # Added ai_auto_routing feature flag
└── environments/
    └── production.rb                   # AI provider configs
```

### Test & Demo Scripts
```
helpforce/
├── create_helpforce_demo_data.rb       # Generates test data
├── test_routing_api.rb                 # Tests all routing endpoints
├── test_route_simple.rb                # Simple routing test
├── test_ai_simple.rb                   # Tests AI endpoints
├── helpforce_demo.rb                   # Complete platform demo
└── open_helpforce_dashboard.sh         # Opens browser to dashboard
```

---

## Installation & Setup

### Prerequisites
- Ruby 3.4.4+ (managed via rbenv)
- PostgreSQL 12+
- Redis 6+
- Node.js 16+
- pnpm package manager

### Initial Setup

1. **Start the application:**
```bash
cd /Users/brianc/Desktop/Newnew/helpforce
overmind start -f Procfile.dev
# OR
foreman start -f Procfile.dev
```

2. **Access the application:**
- URL: http://localhost:3000
- Login: admin@helpforce.test
- Password: Password123!

3. **Navigate to HelpForce:**
- After login, go to: Settings → HelpForce
- Direct URL: http://localhost:3000/app/accounts/1/settings/helpforce

4. **Configure AI Provider:**
- Go to AI Settings tab
- Enter your OpenAI API key
- Select default model (gpt-4o recommended)
- Test connection

5. **Install AI Agents:**
- Go to Marketplace tab
- Click "Install" on desired agents
- Recommended starter agents:
  - Technical Support Specialist
  - Billing & Payments Expert
  - Customer Onboarding Guide

---

## Core Features Detailed

### 1. Multi-Model AI Support

**Location:** `app/services/helpforce/ai/multi_model_service.rb`

**Key Methods:**
```ruby
# Initialize service
ai_service = Helpforce::Ai::MultiModelService.new(account: account)

# Generate chat completion
response = ai_service.chat_completion(
  messages: [
    { role: 'system', content: 'You are a helpful assistant' },
    { role: 'user', content: 'Hello!' }
  ],
  temperature: 0.7
)

# Analyze sentiment
sentiment = ai_service.analyze_sentiment("I'm really frustrated!")
# Returns: { sentiment: 'negative', confidence: 'high', score: -0.8 }

# Rephrase text
rephrased = ai_service.rephrase_text(
  "hey whats up", 
  style: 'professional'
)
# Returns: { content: "Hello, how may I assist you today?" }

# Extract sentiment (simpler version)
sentiment = ai_service.extract_sentiment("Great service!")
# Returns: 'positive'
```

**Supported Providers:**
- OpenAI (GPT-3.5, GPT-4, GPT-4o)
- Claude (Claude 2, Claude 3)
- Google Gemini (Gemini Pro)

### 2. AI Agent Marketplace

**Location:** `app/controllers/api/v1/accounts/integrations/helpforce_marketplace_controller.rb`

**Available Agents:**

1. **Technical Support Specialist** (`technical_support`)
   - Category: technical
   - Specialties: Debugging, troubleshooting, error analysis
   - Best for: Software issues, bugs, technical questions

2. **Billing & Payments Expert** (`billing_support`)
   - Category: billing
   - Specialties: Payment issues, subscription management, refunds
   - Best for: Financial queries, billing disputes

3. **Customer Onboarding Guide** (`onboarding_guide`)
   - Category: onboarding
   - Specialties: Setup assistance, feature tours, best practices
   - Best for: New users, initial configuration

4. **Sales Assistant** (`sales_assistant`)
   - Category: sales
   - Specialties: Product info, pricing, plan comparisons
   - Best for: Pre-sales questions, upgrades

5. **Multilingual Support Agent** (`multilingual_support`)
   - Category: multilingual
   - Specialties: Multiple language support
   - Best for: Non-English customers

6. **Escalation Manager** (`escalation_manager`)
   - Category: escalation
   - Specialties: Urgent issues, complaint handling
   - Best for: High-priority problems

**Managing Agents:**
```ruby
# In Rails console or service
marketplace = Helpforce::MarketplaceService.new(account)

# List all available agents
agents = marketplace.list_available_agents

# Install an agent
marketplace.install_agent('technical_support')

# Uninstall an agent
marketplace.uninstall_agent(agent_id)

# Get agent details
agent = HelpforceAgent.find_by(agent_id: 'technical_support')
```

### 3. Smart Conversation Routing

**Location:** `lib/helpforce/routing/smart_conversation_router.rb`

**How It Works:**

1. **Conversation Analysis:**
   - Extracts text content from messages
   - Detects category (technical, billing, etc.)
   - Analyzes sentiment (positive/negative/neutral)
   - Determines urgency level
   - Identifies language
   - Assesses complexity

2. **Agent Matching:**
   - Scores each available agent based on:
     - Category match (40 points max)
     - Capability match (25 points max)
     - Priority match (30 points max)
     - Language match (20 points max)
     - Performance bonus (15 points max)
     - Availability (10 points max)

3. **Assignment:**
   - Selects highest-scoring agent
   - Creates assignment record
   - Tracks confidence score
   - Logs routing reasons

**Manual Routing:**
```ruby
# Force route a conversation
routing_service = Helpforce::RoutingService.new(account)
result = routing_service.route_new_conversation(conversation)

# Get routing recommendations
recommendations = routing_service.get_routing_recommendations(conversation)

# Manually assign agent
routing_service.assign_agent_to_conversation(
  conversation, 
  agent, 
  assigned_by_user
)
```

### 4. Analytics & Metrics

**Location:** `app/controllers/api/v1/accounts/integrations/helpforce_routing_controller.rb`

**Available Analytics:**

1. **Routing Overview:**
   - Total assignments
   - Auto vs manual routing
   - Average confidence scores
   - Success rates

2. **Agent Performance:**
   - Active conversations
   - Completed today
   - Average handling time
   - Customer satisfaction scores

3. **Routing Trends:**
   - Daily/weekly patterns
   - Category distribution
   - Escalation rates

**Accessing Analytics:**
```ruby
# Get routing analytics
analytics = ConversationAgentAssignment.routing_analytics(account, 7.days)

# Get agent workload
workload = ConversationAgentAssignment.agent_workload_analysis(agent, 7.days)

# Track metrics
AgentMetric.create!(
  helpforce_agent: agent,
  metric_type: 'conversation_completed',
  value: 1,
  metadata: { resolution_time: 300 }
)
```

---

## API Reference

### Base URL
```
http://localhost:3000/api/v1/accounts/{account_id}/integrations
```

### Authentication
All requests require API token in header:
```
api_access_token: YOUR_API_TOKEN
```

### AI Endpoints

#### Get AI Status
```http
GET /helpforce_ai
```
Response:
```json
{
  "configured": true,
  "default_provider": "openai",
  "providers": {
    "openai": { "configured": true, "models": ["gpt-3.5-turbo", "gpt-4"] },
    "claude": { "configured": false },
    "gemini": { "configured": false }
  }
}
```

#### Analyze Sentiment
```http
POST /helpforce_ai/analyze_sentiment
Body: { "text": "I love this product!" }
```
Response:
```json
{
  "sentiment": "positive",
  "confidence": "high",
  "score": 0.92
}
```

#### Rephrase Text
```http
POST /helpforce_ai/rephrase_text
Body: { 
  "text": "hey whats up",
  "style": "professional" 
}
```
Response:
```json
{
  "success": true,
  "original": "hey whats up",
  "content": "Hello, how may I assist you today?",
  "style": "professional"
}
```

#### Chat Completion
```http
POST /helpforce_ai/chat_completion
Body: {
  "messages": [
    { "role": "system", "content": "You are helpful" },
    { "role": "user", "content": "Hello" }
  ],
  "temperature": 0.7,
  "max_tokens": 150
}
```

### Marketplace Endpoints

#### List Agents
```http
GET /helpforce_marketplace
```

#### Install Agent
```http
POST /helpforce_marketplace/install/{agent_id}
```

#### Uninstall Agent
```http
DELETE /helpforce_marketplace/uninstall/{agent_id}
```

### Routing Endpoints

#### Route Conversation
```http
POST /helpforce_routing/conversations/{conversation_id}/route
```

#### Get Routing Analytics
```http
GET /helpforce_routing/analytics?time_range=7d
```

#### Get Agent Workload
```http
GET /helpforce_routing/agent_workload?time_range=1d
```

#### Get Conversations Needing Attention
```http
GET /helpforce_routing/needs_attention
```

---

## UI Components Guide

### Accessing HelpForce UI

1. **Main Dashboard:**
   - URL: `/app/accounts/{account_id}/settings/helpforce`
   - Shows overview stats, quick actions, recent activity

2. **Agent Marketplace:**
   - Tab: "Marketplace"
   - Browse available agents
   - One-click install/uninstall
   - View agent details and capabilities

3. **Routing Dashboard:**
   - Tab: "Smart Routing"
   - Real-time routing metrics
   - Agent performance charts
   - Conversation flow visualization

4. **AI Settings:**
   - Tab: "AI Settings"
   - Configure AI providers
   - Set default models
   - Test connections
   - View usage statistics

### Component Interactions

```javascript
// In Vue components

// Install an agent
async installAgent(agentId) {
  const response = await fetch(
    `/api/v1/accounts/${accountId}/integrations/helpforce_marketplace/install/${agentId}`,
    { 
      method: 'POST',
      headers: { 'api_access_token': apiToken }
    }
  );
  // Handle response
}

// Get routing analytics
async fetchAnalytics() {
  const response = await fetch(
    `/api/v1/accounts/${accountId}/integrations/helpforce_routing/analytics`,
    { headers: { 'api_access_token': apiToken } }
  );
  const data = await response.json();
  // Update charts
}
```

---

## Database Schema

### helpforce_agents
```sql
CREATE TABLE helpforce_agents (
  id BIGSERIAL PRIMARY KEY,
  account_id BIGINT NOT NULL,
  user_id BIGINT,
  agent_id VARCHAR NOT NULL,
  name VARCHAR NOT NULL,
  description TEXT,
  category VARCHAR,
  status VARCHAR DEFAULT 'active',
  ai_provider VARCHAR,
  ai_model VARCHAR,
  custom_prompt TEXT,
  temperature DECIMAL(3,2) DEFAULT 0.7,
  max_tokens INTEGER DEFAULT 2000,
  configuration JSONB DEFAULT '{}',
  metrics_data JSONB DEFAULT '{}',
  capabilities TEXT[],
  suggested_responses JSONB,
  icon VARCHAR,
  trigger_conditions JSONB DEFAULT '{}',
  auto_respond BOOLEAN DEFAULT false,
  last_used_at TIMESTAMP,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);
```

### conversation_agent_assignments
```sql
CREATE TABLE conversation_agent_assignments (
  id BIGSERIAL PRIMARY KEY,
  conversation_id BIGINT NOT NULL,
  helpforce_agent_id BIGINT NOT NULL,
  assignment_reason TEXT NOT NULL,
  confidence_score DECIMAL(5,2),
  auto_assigned BOOLEAN DEFAULT false,
  active BOOLEAN DEFAULT true,
  assigned_at TIMESTAMP,
  unassigned_at TIMESTAMP,
  assignment_metadata JSONB DEFAULT '{}',
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);
```

### agent_metrics
```sql
CREATE TABLE agent_metrics (
  id BIGSERIAL PRIMARY KEY,
  helpforce_agent_id BIGINT NOT NULL,
  metric_type VARCHAR NOT NULL,
  value DECIMAL(10,4),
  metric_date DATE,
  recorded_at TIMESTAMP,
  metadata JSONB,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);
```

---

## Configuration

### Environment Variables
```bash
# .env or production environment

# AI Provider Keys
OPENAI_API_KEY=sk-...
ANTHROPIC_API_KEY=sk-ant-...
GOOGLE_GEMINI_API_KEY=...

# Feature Flags
HELPFORCE_ENABLED=true
AI_AUTO_ROUTING_ENABLED=true

# Limits
MAX_AI_REQUESTS_PER_MINUTE=60
MAX_TOKENS_PER_REQUEST=4000
```

### Feature Flags
In `config/features.yml`:
```yaml
- name: ai_auto_routing
  display_name: AI Auto Routing
  enabled: true
  premium: false
  help_url: https://helpforce.app/docs/routing
```

### Rails Configuration
```ruby
# config/initializers/helpforce.rb
Rails.application.config.helpforce = {
  ai_providers: {
    openai: {
      api_key: ENV['OPENAI_API_KEY'],
      default_model: 'gpt-4o',
      timeout: 30
    },
    claude: {
      api_key: ENV['ANTHROPIC_API_KEY'],
      default_model: 'claude-3-opus',
      timeout: 30
    }
  },
  routing: {
    auto_route_new_conversations: true,
    confidence_threshold: 0.7,
    max_wait_time: 5.minutes
  }
}
```

---

## Testing & Demo Scripts

### 1. Generate Test Data
```bash
cd /Users/brianc/Desktop/Newnew/helpforce
rbenv exec bundle exec rails runner create_helpforce_demo_data.rb
```
Creates:
- 5 test conversations with different issue types
- 5 historical resolved conversations
- Agent assignments for analytics

### 2. Test Routing
```bash
rbenv exec ruby test_route_simple.rb [conversation_id]
```
Tests routing a specific conversation to an AI agent.

### 3. Test All APIs
```bash
rbenv exec ruby test_routing_api.rb
```
Tests all HelpForce API endpoints systematically.

### 4. Run Complete Demo
```bash
rbenv exec ruby helpforce_demo.rb
```
Demonstrates all features with formatted output.

### 5. Manual Testing in Rails Console
```ruby
# Start console
bundle exec rails console

# Test AI service
account = Account.first
ai = Helpforce::Ai::MultiModelService.new(account: account)
ai.extract_sentiment("This is amazing!")

# Test routing
conversation = Conversation.find(14)
router = Helpforce::Routing::SmartConversationRouter.new(
  account: account,
  conversation: conversation
)
result = router.route_conversation(force: true)

# Check assignments
ConversationAgentAssignment.last
```

---

## Troubleshooting

### Common Issues

1. **"undefined method 'admin?' for AccountPolicy"**
   - Solution: Added in `app/policies/account_policy.rb`:
   ```ruby
   def admin?
     @account_user.administrator?
   end
   ```

2. **Routing returns nil**
   - Check if account has `ai_auto_routing` feature enabled
   - Ensure conversation has messages
   - Verify agents are installed and active

3. **AI provider not working**
   - Check API key is configured
   - Verify network connectivity
   - Check rate limits

4. **500 errors on routing**
   - Check Rails logs: `tail -f log/development.log`
   - Ensure all services are loaded: `require_relative` in files
   - Verify database migrations ran

### Debug Commands
```bash
# Check running services
ps aux | grep -E "(puma|sidekiq|webpack)"

# View real-time logs
tail -f log/development.log

# Check Redis
redis-cli -p 6380 ping

# Database console
bundle exec rails db

# Clear cache
bundle exec rails tmp:clear
bundle exec rails cache:clear
```

---

## Monetization Strategy

### SaaS Pricing Tiers

1. **Starter - $49/month**
   - 3 AI agents
   - 1,000 AI operations/month
   - Basic analytics
   - Email support

2. **Professional - $149/month**
   - All 6 agents
   - 10,000 AI operations/month
   - Advanced analytics
   - Priority support
   - Custom agent configurations

3. **Enterprise - $499/month**
   - Unlimited agents
   - Unlimited AI operations
   - Custom agent development
   - Dedicated success manager
   - SLA guarantees
   - White-label options

### Usage-Based Add-ons
- Additional AI operations: $10 per 1,000
- Premium agents: $20/month each
- Custom agent development: $2,000 one-time
- Priority routing: $0.10 per conversation

### Revenue Projections
- 100 customers on Professional: $14,900/month
- 20 Enterprise customers: $9,980/month
- Usage overages: ~$5,000/month
- **Total MRR: ~$30,000**

### Go-to-Market Strategy
1. **Freemium Model:** Free tier with 100 operations/month
2. **Partner Program:** Revenue share with Chatwoot
3. **Content Marketing:** SEO-focused blog posts
4. **Product Hunt Launch:** Aim for #1 Product of the Day
5. **AppSumo Deal:** Limited lifetime deals for quick cash

---

## Next Steps

1. **Production Deployment**
   ```bash
   # Heroku deployment
   heroku create helpforce-app
   heroku addons:create heroku-postgresql
   heroku addons:create heroku-redis
   git push heroku main
   heroku run rails db:migrate
   ```

2. **Security Hardening**
   - Implement rate limiting
   - Add request signing
   - Encrypt API keys
   - Add audit logging

3. **Performance Optimization**
   - Implement caching layer
   - Background job processing
   - Database query optimization
   - CDN for static assets

4. **Feature Roadmap**
   - Voice AI integration
   - Slack/Teams integration
   - Custom agent builder UI
   - A/B testing for responses
   - Conversation insights dashboard

---

## Support & Documentation

- **GitHub Repository:** [Your GitHub URL]
- **Documentation Site:** https://docs.helpforce.app
- **API Reference:** https://api.helpforce.app/docs
- **Support Email:** support@helpforce.app
- **Community Slack:** https://helpforce.slack.com

---

*Built with ❤️ on top of Chatwoot - Transforming customer support with AI*