/* global axios */
import ApiClient from './ApiClient';

class HelpforceAIAPI extends ApiClient {
  constructor() {
    super('helpforce_ai', { accountScoped: true });
  }

  // Get AI provider status and configuration
  getProvidersStatus() {
    return axios.get(this.url);
  }

  // Configure AI provider
  configureProvider(provider, apiKey, model = null) {
    return axios.post(`${this.url}/configure_provider`, {
      provider,
      api_key: apiKey,
      model,
    });
  }

  // Test AI provider connection
  testProvider(provider) {
    return axios.post(`${this.url}/test_provider`, {
      provider,
    });
  }

  // Multi-model chat completion
  chatCompletion(messages, options = {}) {
    return axios.post(`${this.url}/chat_completion`, {
      messages,
      provider: options.provider,
      model: options.model,
      options: {
        temperature: options.temperature,
        max_tokens: options.max_tokens,
        ...options,
      },
    });
  }

  // Rephrase text with different styles
  rephraseText(text, style = 'professional', provider = null) {
    return axios.post(`${this.url}/rephrase_text`, {
      text,
      style,
      provider,
    });
  }

  // Analyze sentiment of text
  analyzeSentiment(text, provider = null) {
    return axios.post(`${this.url}/analyze_sentiment`, {
      text,
      provider,
    });
  }

  // Categorize conversation
  categorizeConversation(conversationId, categories = null, provider = null) {
    return axios.post(`${this.url}/categorize_conversation`, {
      conversation_id: conversationId,
      categories,
      provider,
    });
  }

  // Bulk operations on conversations
  bulkOperations(operation, conversationIds, options = {}) {
    return axios.post(`${this.url}/bulk_operations`, {
      operation,
      conversation_ids: conversationIds,
      provider: options.provider,
      options,
    });
  }

  // Convenience methods for common operations
  summarizeConversations(conversationIds, provider = null) {
    return this.bulkOperations('summarize', conversationIds, { provider });
  }

  categorizeConversations(conversationIds, provider = null) {
    return this.bulkOperations('categorize', conversationIds, { provider });
  }

  analyzeSentimentBulk(conversationIds, provider = null) {
    return this.bulkOperations('sentiment', conversationIds, { provider });
  }

  // Text improvement operations
  improveText(text, operation, provider = null) {
    const operationMap = {
      friendly: () => this.rephraseText(text, 'friendly', provider),
      formal: () => this.rephraseText(text, 'formal', provider),
      professional: () => this.rephraseText(text, 'professional', provider),
      casual: () => this.rephraseText(text, 'casual', provider),
      concise: () => this.rephraseText(text, 'concise', provider),
      detailed: () => this.rephraseText(text, 'detailed', provider),
    };

    const operation_func = operationMap[operation];
    if (!operation_func) {
      throw new Error(`Unsupported text improvement operation: ${operation}`);
    }

    return operation_func();
  }

  // Translate text
  translateText(text, targetLanguage = 'English', provider = null) {
    return this.chatCompletion(
      [
        {
          role: 'user',
          content: `Translate the following text to ${targetLanguage}. Return only the translated text:\n\n${text}`,
        },
      ],
      { provider }
    );
  }

  // Extract entities from text
  extractEntities(text, provider = null) {
    return this.chatCompletion(
      [
        {
          role: 'user',
          content: `Extract important entities (names, companies, products, issues) from this text. Return as a JSON array:\n\n${text}`,
        },
      ],
      { provider }
    );
  }

  // Generate FAQ from conversations
  generateFAQ(conversationIds, provider = null) {
    return this.chatCompletion(
      [
        {
          role: 'user',
          content: 'Generate FAQ items from the provided conversations.',
        },
      ],
      { provider, conversation_ids: conversationIds }
    );
  }
}

export default new HelpforceAIAPI();
