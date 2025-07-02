import { ref, computed, reactive } from 'vue';
import { useAlert } from 'dashboard/composables';
import HelpforceMarketplaceAPI from 'dashboard/api/helpforceMarketplace';

export function useHelpforceMarketplace() {
  const isLoading = ref(false);
  const marketplace = ref([]);
  const installedAgents = ref([]);
  const selectedAgent = ref(null);
  const { showAlert } = useAlert();

  // Reactive filters and search
  const filters = reactive({
    category: '',
    pricing: '',
    search: '',
  });

  // Marketplace state
  const marketplaceState = reactive({
    categories: [],
    totalAvailable: 0,
    installedCount: 0,
    lastUpdated: null,
  });

  // Computed properties
  const filteredAgents = computed(() => {
    if (!marketplace.value.length) return [];

    return marketplace.value.filter(agent => {
      if (filters.category && agent.category !== filters.category) return false;
      if (filters.pricing && agent.pricing !== filters.pricing) return false;
      if (filters.search) {
        const query = filters.search.toLowerCase();
        return (
          agent.name.toLowerCase().includes(query) ||
          agent.description.toLowerCase().includes(query) ||
          agent.capabilities.some(cap => cap.toLowerCase().includes(query))
        );
      }
      return true;
    });
  });

  const agentsByCategory = computed(() => {
    const grouped = {};
    filteredAgents.value.forEach(agent => {
      if (!grouped[agent.category]) {
        grouped[agent.category] = [];
      }
      grouped[agent.category].push(agent);
    });
    return grouped;
  });

  const freeAgents = computed(() => {
    return filteredAgents.value.filter(agent => agent.pricing === 'free');
  });

  const premiumAgents = computed(() => {
    return filteredAgents.value.filter(agent => agent.pricing === 'premium');
  });

  const installedAgentIds = computed(() => {
    return installedAgents.value.map(agent => agent.agent_id);
  });

  const availableAgents = computed(() => {
    return filteredAgents.value.filter(agent => !agent.installed);
  });

  // Core methods
  const loadMarketplace = async (forceRefresh = false) => {
    if (marketplace.value.length && !forceRefresh) return;

    try {
      isLoading.value = true;
      const response = await HelpforceMarketplaceAPI.getMarketplace(filters);

      marketplace.value = response.data.agents;
      marketplaceState.categories = response.data.categories;
      marketplaceState.totalAvailable = response.data.total_available;
      marketplaceState.installedCount = response.data.installed_count;
      marketplaceState.lastUpdated = new Date();

      return response.data;
    } catch (error) {
      console.error('Failed to load marketplace:', error);
      showAlert('Failed to load marketplace');
      throw error;
    } finally {
      isLoading.value = false;
    }
  };

  const loadInstalledAgents = async () => {
    try {
      isLoading.value = true;
      const response = await HelpforceMarketplaceAPI.getInstalledAgents();
      installedAgents.value = response.data.installed_agents;
      return response.data;
    } catch (error) {
      console.error('Failed to load installed agents:', error);
      showAlert('Failed to load installed agents');
      throw error;
    } finally {
      isLoading.value = false;
    }
  };

  const getAgentDetails = async agentId => {
    try {
      isLoading.value = true;
      const response = await HelpforceMarketplaceAPI.getAgent(agentId);
      selectedAgent.value = response.data;
      return response.data;
    } catch (error) {
      console.error(`Failed to get agent ${agentId}:`, error);
      showAlert('Failed to load agent details');
      throw error;
    } finally {
      isLoading.value = false;
    }
  };

  const installAgent = async agentId => {
    try {
      isLoading.value = true;
      const response = await HelpforceMarketplaceAPI.installAgent(agentId);

      if (response.data.success) {
        showAlert(`${response.data.agent.name} installed successfully`);

        // Update local state
        const agentIndex = marketplace.value.findIndex(a => a.id === agentId);
        if (agentIndex !== -1) {
          marketplace.value[agentIndex].installed = true;
        }

        // Refresh installed agents
        await loadInstalledAgents();

        return response.data;
      }
      throw new Error(response.data.error);
    } catch (error) {
      console.error(`Failed to install agent ${agentId}:`, error);

      if (error.response?.status === 402) {
        showAlert('Premium subscription required for this agent');
      } else {
        showAlert(`Installation failed: ${error.message}`);
      }

      throw error;
    } finally {
      isLoading.value = false;
    }
  };

  const uninstallAgent = async agentId => {
    try {
      isLoading.value = true;
      const response = await HelpforceMarketplaceAPI.uninstallAgent(agentId);

      if (response.data.success) {
        showAlert(response.data.message);

        // Update local state
        const agentIndex = marketplace.value.findIndex(a => a.id === agentId);
        if (agentIndex !== -1) {
          marketplace.value[agentIndex].installed = false;
        }

        // Remove from installed agents
        installedAgents.value = installedAgents.value.filter(
          a => a.agent_id !== agentId
        );

        return response.data;
      }
      throw new Error(response.data.error);
    } catch (error) {
      console.error(`Failed to uninstall agent ${agentId}:`, error);
      showAlert(`Uninstallation failed: ${error.message}`);
      throw error;
    } finally {
      isLoading.value = false;
    }
  };

  const configureAgent = async (agentId, configuration) => {
    try {
      isLoading.value = true;
      const response = await HelpforceMarketplaceAPI.configureAgent(
        agentId,
        configuration
      );

      if (response.data.success) {
        showAlert('Agent configuration updated');

        // Update local installed agent
        const agentIndex = installedAgents.value.findIndex(
          a => a.agent_id === agentId
        );
        if (agentIndex !== -1) {
          Object.assign(installedAgents.value[agentIndex], response.data.agent);
        }

        return response.data;
      }
      throw new Error(response.data.error);
    } catch (error) {
      console.error(`Failed to configure agent ${agentId}:`, error);
      showAlert(`Configuration failed: ${error.message}`);
      throw error;
    } finally {
      isLoading.value = false;
    }
  };

  const testAgent = async (agentId, testMessage = null) => {
    try {
      isLoading.value = true;
      const response = await HelpforceMarketplaceAPI.testAgent(
        agentId,
        testMessage
      );

      if (response.data.success) {
        showAlert('Agent test completed successfully');
        return response.data;
      }
      throw new Error(response.data.error);
    } catch (error) {
      console.error(`Failed to test agent ${agentId}:`, error);
      showAlert(`Agent test failed: ${error.message}`);
      throw error;
    } finally {
      isLoading.value = false;
    }
  };

  const getRecommendations = async (conversationId = null) => {
    try {
      const response =
        await HelpforceMarketplaceAPI.getRecommendations(conversationId);
      return response.data;
    } catch (error) {
      console.error('Failed to get recommendations:', error);
      showAlert('Failed to load recommendations');
      throw error;
    }
  };

  const getAnalytics = async (timeRange = '30d') => {
    try {
      const response = await HelpforceMarketplaceAPI.getAnalytics(timeRange);
      return response.data;
    } catch (error) {
      console.error('Failed to get analytics:', error);
      showAlert('Failed to load analytics');
      throw error;
    }
  };

  // Utility methods
  const searchAgents = query => {
    filters.search = query;
  };

  const filterByCategory = category => {
    filters.category = category;
  };

  const filterByPricing = pricing => {
    filters.pricing = pricing;
  };

  const clearFilters = () => {
    filters.category = '';
    filters.pricing = '';
    filters.search = '';
  };

  const isAgentInstalled = agentId => {
    return installedAgentIds.value.includes(agentId);
  };

  const getInstalledAgent = agentId => {
    return installedAgents.value.find(agent => agent.agent_id === agentId);
  };

  const getAgentPerformance = agentId => {
    const agent = getInstalledAgent(agentId);
    return agent ? agent.performance : null;
  };

  // Bulk operations
  const installMultipleAgents = async agentIds => {
    try {
      isLoading.value = true;
      const results = [];

      for (const agentId of agentIds) {
        try {
          const result = await installAgent(agentId);
          results.push({ agentId, success: true, data: result });
        } catch (error) {
          results.push({ agentId, success: false, error: error.message });
        }
      }

      const successCount = results.filter(r => r.success).length;
      showAlert(
        `${successCount} of ${agentIds.length} agents installed successfully`
      );

      return results;
    } catch (error) {
      console.error('Bulk installation failed:', error);
      throw error;
    } finally {
      isLoading.value = false;
    }
  };

  // Quick setup methods
  const quickSetupForTechnicalSupport = async () => {
    const recommendedAgents = ['technical_support', 'escalation_manager'];
    return installMultipleAgents(recommendedAgents);
  };

  const quickSetupForSales = async () => {
    const recommendedAgents = ['sales_assistant', 'onboarding_guide'];
    return installMultipleAgents(recommendedAgents);
  };

  const quickSetupForGlobalSupport = async () => {
    const recommendedAgents = [
      'multilingual_support',
      'technical_support',
      'billing_support',
    ];
    return installMultipleAgents(recommendedAgents);
  };

  // Configuration presets
  const applyConfigurationPreset = async (agentId, presetName) => {
    const presets = HelpforceMarketplaceAPI.getConfigurationPresets();
    const preset = presets[presetName];

    if (!preset) {
      showAlert(`Unknown configuration preset: ${presetName}`);
      return;
    }

    return configureAgent(agentId, preset);
  };

  // Initialize
  const initialize = async () => {
    await Promise.all([loadMarketplace(), loadInstalledAgents()]);
  };

  return {
    // State
    isLoading,
    marketplace,
    installedAgents,
    selectedAgent,
    filters,
    marketplaceState,

    // Computed
    filteredAgents,
    agentsByCategory,
    freeAgents,
    premiumAgents,
    installedAgentIds,
    availableAgents,

    // Core methods
    loadMarketplace,
    loadInstalledAgents,
    getAgentDetails,
    installAgent,
    uninstallAgent,
    configureAgent,
    testAgent,
    getRecommendations,
    getAnalytics,

    // Utility methods
    searchAgents,
    filterByCategory,
    filterByPricing,
    clearFilters,
    isAgentInstalled,
    getInstalledAgent,
    getAgentPerformance,

    // Bulk operations
    installMultipleAgents,
    quickSetupForTechnicalSupport,
    quickSetupForSales,
    quickSetupForGlobalSupport,

    // Configuration
    applyConfigurationPreset,

    // Initialize
    initialize,
  };
}
