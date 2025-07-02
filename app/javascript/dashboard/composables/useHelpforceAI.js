import { ref, computed, reactive } from 'vue';
import { useAlert } from 'dashboard/composables';
import HelpforceAIAPI from 'dashboard/api/helpforceAI';

export function useHelpforceAI() {
  const isLoading = ref(false);
  const providersStatus = ref({});
  const { showAlert } = useAlert();

  // Reactive state for AI operations
  const aiState = reactive({
    selectedProvider: null,
    availableProviders: [],
    isConfiguring: false,
    lastOperation: null,
    operationHistory: [],
  });

  // Computed properties
  const hasConfiguredProviders = computed(() => {
    return Object.values(providersStatus.value).some(
      provider => provider.configured
    );
  });

  const defaultProvider = computed(() => {
    const configured = Object.entries(providersStatus.value).find(
      ([, config]) => config.configured
    );
    return configured ? configured[0] : 'openai';
  });

  const availableModels = computed(() => {
    if (
      !aiState.selectedProvider ||
      !providersStatus.value[aiState.selectedProvider]
    ) {
      return [];
    }
    return (
      providersStatus.value[aiState.selectedProvider].available_models || []
    );
  });

  // Core API methods
  const loadProvidersStatus = async () => {
    try {
      isLoading.value = true;
      const response = await HelpforceAIAPI.getProvidersStatus();
      providersStatus.value = response.data.providers;
      aiState.availableProviders = Object.keys(response.data.providers);
      aiState.selectedProvider =
        aiState.selectedProvider || defaultProvider.value;
      return response.data;
    } catch (error) {
      console.error('Failed to load AI providers status:', error);
      showAlert('Failed to load AI providers status');
      throw error;
    } finally {
      isLoading.value = false;
    }
  };

  const configureProvider = async (provider, apiKey, model = null) => {
    try {
      aiState.isConfiguring = true;
      const response = await HelpforceAIAPI.configureProvider(
        provider,
        apiKey,
        model
      );

      if (response.data.success) {
        showAlert(`${provider.toUpperCase()} configured successfully`);
        await loadProvidersStatus(); // Refresh status
        return response.data;
      }
      throw new Error(response.data.error);
    } catch (error) {
      console.error(`Failed to configure ${provider}:`, error);
      showAlert(`Failed to configure ${provider}: ${error.message}`);
      throw error;
    } finally {
      aiState.isConfiguring = false;
    }
  };

  const testProvider = async provider => {
    try {
      isLoading.value = true;
      const response = await HelpforceAIAPI.testProvider(provider);

      if (response.data.success) {
        showAlert(`${provider.toUpperCase()} connection test successful`);
        return response.data;
      }
      throw new Error(response.data.error);
    } catch (error) {
      console.error(`Failed to test ${provider}:`, error);
      showAlert(`Connection test failed for ${provider}: ${error.message}`);
      throw error;
    } finally {
      isLoading.value = false;
    }
  };

  // AI Operations
  const chatCompletion = async (messages, options = {}) => {
    try {
      isLoading.value = true;
      const provider = options.provider || aiState.selectedProvider;
      const response = await HelpforceAIAPI.chatCompletion(messages, {
        ...options,
        provider,
      });

      aiState.lastOperation = {
        type: 'chat_completion',
        provider: response.data.provider,
        model: response.data.model,
        timestamp: new Date(),
      };

      return response.data;
    } catch (error) {
      console.error('Chat completion failed:', error);
      showAlert('AI chat completion failed');
      throw error;
    } finally {
      isLoading.value = false;
    }
  };

  const rephraseText = async (
    text,
    style = 'professional',
    provider = null
  ) => {
    try {
      isLoading.value = true;
      const targetProvider = provider || aiState.selectedProvider;
      const response = await HelpforceAIAPI.rephraseText(
        text,
        style,
        targetProvider
      );

      aiState.lastOperation = {
        type: 'rephrase',
        style,
        provider: targetProvider,
        timestamp: new Date(),
      };

      return response.data;
    } catch (error) {
      console.error('Text rephrasing failed:', error);
      showAlert('Text rephrasing failed');
      throw error;
    } finally {
      isLoading.value = false;
    }
  };

  const analyzeSentiment = async (text, provider = null) => {
    try {
      isLoading.value = true;
      const targetProvider = provider || aiState.selectedProvider;
      const response = await HelpforceAIAPI.analyzeSentiment(
        text,
        targetProvider
      );

      aiState.lastOperation = {
        type: 'sentiment_analysis',
        provider: targetProvider,
        timestamp: new Date(),
      };

      return response.data;
    } catch (error) {
      console.error('Sentiment analysis failed:', error);
      showAlert('Sentiment analysis failed');
      throw error;
    } finally {
      isLoading.value = false;
    }
  };

  const categorizeConversation = async (
    conversationId,
    categories = null,
    provider = null
  ) => {
    try {
      isLoading.value = true;
      const targetProvider = provider || aiState.selectedProvider;
      const response = await HelpforceAIAPI.categorizeConversation(
        conversationId,
        categories,
        targetProvider
      );

      aiState.lastOperation = {
        type: 'categorize_conversation',
        provider: targetProvider,
        timestamp: new Date(),
      };

      return response.data;
    } catch (error) {
      console.error('Conversation categorization failed:', error);
      showAlert('Conversation categorization failed');
      throw error;
    } finally {
      isLoading.value = false;
    }
  };

  // Bulk operations
  const performBulkOperation = async (
    operation,
    conversationIds,
    options = {}
  ) => {
    try {
      isLoading.value = true;
      const provider = options.provider || aiState.selectedProvider;
      const response = await HelpforceAIAPI.bulkOperations(
        operation,
        conversationIds,
        {
          ...options,
          provider,
        }
      );

      aiState.lastOperation = {
        type: 'bulk_operation',
        operation,
        provider,
        count: conversationIds.length,
        timestamp: new Date(),
      };

      showAlert(
        `Bulk ${operation} completed for ${response.data.processed_count} conversations`
      );
      return response.data;
    } catch (error) {
      console.error(`Bulk ${operation} failed:`, error);
      showAlert(`Bulk ${operation} operation failed`);
      throw error;
    } finally {
      isLoading.value = false;
    }
  };

  // Convenience methods for common operations
  const improveText = async (text, operation, provider = null) => {
    return rephraseText(text, operation, provider);
  };

  const translateText = async (
    text,
    targetLanguage = 'English',
    provider = null
  ) => {
    try {
      isLoading.value = true;
      const targetProvider = provider || aiState.selectedProvider;
      const response = await HelpforceAIAPI.translateText(
        text,
        targetLanguage,
        targetProvider
      );
      return response.data;
    } catch (error) {
      console.error('Translation failed:', error);
      showAlert('Translation failed');
      throw error;
    } finally {
      isLoading.value = false;
    }
  };

  // Provider management utilities
  const setSelectedProvider = provider => {
    if (aiState.availableProviders.includes(provider)) {
      aiState.selectedProvider = provider;
    }
  };

  const getProviderInfo = provider => {
    return providersStatus.value[provider] || {};
  };

  const isProviderConfigured = provider => {
    return getProviderInfo(provider).configured || false;
  };

  // Operation history management
  const addToHistory = operation => {
    aiState.operationHistory.unshift(operation);
    if (aiState.operationHistory.length > 50) {
      aiState.operationHistory = aiState.operationHistory.slice(0, 50);
    }
  };

  const clearHistory = () => {
    aiState.operationHistory = [];
  };

  // Initialize on first use
  const initialize = async () => {
    await loadProvidersStatus();
  };

  return {
    // State
    isLoading,
    providersStatus,
    aiState,

    // Computed
    hasConfiguredProviders,
    defaultProvider,
    availableModels,

    // Core methods
    loadProvidersStatus,
    configureProvider,
    testProvider,
    initialize,

    // AI Operations
    chatCompletion,
    rephraseText,
    analyzeSentiment,
    categorizeConversation,
    performBulkOperation,
    improveText,
    translateText,

    // Utilities
    setSelectedProvider,
    getProviderInfo,
    isProviderConfigured,
    addToHistory,
    clearHistory,
  };
}
