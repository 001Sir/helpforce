/* global axios */
import ApiClient from './ApiClient';

class HelpforceMarketplaceAPI extends ApiClient {
  constructor() {
    super('helpforce_marketplace', { accountScoped: true });
  }

  // Get all available agents in marketplace
  getMarketplace(filters = {}) {
    const params = new URLSearchParams();

    if (filters.category) params.append('category', filters.category);
    if (filters.pricing) params.append('pricing', filters.pricing);
    if (filters.search) params.append('search', filters.search);

    const queryString = params.toString();
    const url = queryString ? `${this.url}?${queryString}` : this.url;

    return axios.get(url);
  }

  // Get specific agent details
  getAgent(agentId) {
    return axios.get(`${this.url}/${agentId}`);
  }

  // Install an agent
  installAgent(agentId) {
    return axios.post(`${this.url}/${agentId}/install`);
  }

  // Uninstall an agent
  uninstallAgent(agentId) {
    return axios.delete(`${this.url}/${agentId}/uninstall`);
  }

  // Configure installed agent
  configureAgent(agentId, configuration) {
    return axios.patch(`${this.url}/${agentId}/configure`, {
      configuration,
    });
  }

  // Test agent with sample message
  testAgent(agentId, testMessage = null) {
    return axios.post(`${this.url}/${agentId}/test`, {
      test_message: testMessage,
    });
  }

  // Get installed agents
  getInstalledAgents() {
    return axios.get(`${this.url}/installed`);
  }

  // Get agent recommendations
  getRecommendations(conversationId = null) {
    const params = conversationId ? { conversation_id: conversationId } : {};
    return axios.get(`${this.url}/recommendations`, { params });
  }

  // Get marketplace analytics
  getAnalytics(timeRange = '30d') {
    return axios.get(`${this.url}/analytics`, {
      params: { time_range: timeRange },
    });
  }

  // Convenience methods for common operations
  searchAgents(query) {
    return this.getMarketplace({ search: query });
  }

  getAgentsByCategory(category) {
    return this.getMarketplace({ category });
  }

  getFreeAgents() {
    return this.getMarketplace({ pricing: 'free' });
  }

  getPremiumAgents() {
    return this.getMarketplace({ pricing: 'premium' });
  }

  // Agent management shortcuts
  async installAndConfigure(agentId, configuration = {}) {
    try {
      const installResult = await this.installAgent(agentId);

      if (Object.keys(configuration).length > 0) {
        const configResult = await this.configureAgent(agentId, configuration);
        return { install: installResult.data, configure: configResult.data };
      }

      return { install: installResult.data };
    } catch (error) {
      throw error;
    }
  }

  async quickTest(agentId, message = 'Hello, can you help me?') {
    return this.testAgent(agentId, message);
  }

  // Bulk operations
  async installMultipleAgents(agentIds) {
    const results = [];

    for (const agentId of agentIds) {
      try {
        const result = await this.installAgent(agentId);
        results.push({ agentId, success: true, data: result.data });
      } catch (error) {
        results.push({ agentId, success: false, error: error.message });
      }
    }

    return results;
  }

  // Agent performance helpers
  async getAgentPerformance(agentId) {
    const installedAgents = await this.getInstalledAgents();
    const agent = installedAgents.data.installed_agents.find(
      a => a.agent_id === agentId
    );
    return agent ? agent.performance : null;
  }

  // Recommendation helpers
  async getSmartRecommendations(conversationHistory = []) {
    // Analyze conversation history and get targeted recommendations
    if (conversationHistory.length > 0) {
      // Use the last conversation for recommendations
      const lastConversation =
        conversationHistory[conversationHistory.length - 1];
      return this.getRecommendations(lastConversation.id);
    }

    return this.getRecommendations();
  }

  // Installation validation
  async validateInstallation(agentId) {
    try {
      const testResult = await this.testAgent(agentId, 'Installation test');
      return {
        valid: testResult.data.success,
        response: testResult.data.agent_response,
        provider: testResult.data.provider_used,
        model: testResult.data.model_used,
      };
    } catch (error) {
      return {
        valid: false,
        error: error.message,
      };
    }
  }

  // Configuration presets
  getConfigurationPresets() {
    return {
      conservative: {
        temperature: 0.3,
        max_tokens: 1500,
        auto_respond: false,
      },
      balanced: {
        temperature: 0.7,
        max_tokens: 2000,
        auto_respond: false,
      },
      creative: {
        temperature: 0.9,
        max_tokens: 2500,
        auto_respond: false,
      },
      auto_pilot: {
        temperature: 0.5,
        max_tokens: 2000,
        auto_respond: true,
        trigger_conditions: {
          sentiment: ['neutral', 'positive'],
          keywords: ['help', 'question', 'issue'],
        },
      },
    };
  }

  // Apply configuration preset
  async applyPreset(agentId, presetName) {
    const presets = this.getConfigurationPresets();
    const preset = presets[presetName];

    if (!preset) {
      throw new Error(`Unknown preset: ${presetName}`);
    }

    return this.configureAgent(agentId, preset);
  }
}

export default new HelpforceMarketplaceAPI();
