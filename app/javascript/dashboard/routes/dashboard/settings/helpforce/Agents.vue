<script setup>
import { ref, computed, onMounted } from 'vue';
import { useRouter, useRoute } from 'vue-router';
import { useAlert } from 'dashboard/composables';
import { useHelpforceMarketplace } from 'dashboard/composables/useHelpforceMarketplace';

const router = useRouter();
const route = useRoute();
const { showAlert } = useAlert();

const {
  isLoading,
  installedAgents,
  loadInstalledAgents,
  configureAgent: updateAgent,
  testAgent: performAgentTest,
} = useHelpforceMarketplace();

// Local reactive state
const showConfigModal = ref(false);
const showTestModal = ref(false);
const selectedAgent = ref(null);
const isSaving = ref(false);
const isTesting = ref(false);
const testMessage = ref('');
const testResponse = ref('');
const testResponseTime = ref(0);

const agentConfig = ref({
  temperature: 0.7,
  max_tokens: 2000,
  auto_respond: false,
  custom_prompt: '',
  ai_provider: 'openai',
});

// Computed properties
const activeAgents = computed(() => {
  return installedAgents.value.filter(agent => agent.status === 'active')
    .length;
});

const totalConversations = computed(() => {
  return installedAgents.value.reduce(
    (sum, agent) => sum + (agent.total_conversations || 0),
    0
  );
});

const averagePerformance = computed(() => {
  if (installedAgents.value.length === 0) return 0;
  const total = installedAgents.value.reduce(
    (sum, agent) => sum + (agent.success_rate || 85),
    0
  );
  return Math.round(total / installedAgents.value.length);
});

const testTemplates = computed(() => {
  if (!selectedAgent.value) return [];

  const category = selectedAgent.value.category;
  const templates = {
    technical: [
      {
        label: 'Error Report',
        message: "I'm getting a 500 error when trying to log in",
        preview: 'Server error issue',
      },
      {
        label: 'Feature Request',
        message: 'How do I configure the advanced settings?',
        preview: 'Configuration help',
      },
    ],
    billing: [
      {
        label: 'Payment Issue',
        message: 'I was charged twice for my subscription',
        preview: 'Billing problem',
      },
      {
        label: 'Refund Request',
        message: 'I need a refund for my last payment',
        preview: 'Refund inquiry',
      },
    ],
    sales: [
      {
        label: 'Demo Request',
        message: "I'd like to schedule a demo of your enterprise plan",
        preview: 'Sales inquiry',
      },
      {
        label: 'Pricing Question',
        message: "What's included in the premium package?",
        preview: 'Pricing info',
      },
    ],
  };

  return (
    templates[category] || [
      {
        label: 'General Help',
        message: 'I need help with my account',
        preview: 'General inquiry',
      },
      {
        label: 'Urgent Issue',
        message: 'This is urgent, I need immediate help',
        preview: 'High priority',
      },
    ]
  );
});

// Methods
const refreshAgents = async () => {
  try {
    await loadInstalledAgents();
    showAlert('Agent data refreshed');
  } catch (error) {
    showAlert('Failed to refresh agent data');
  }
};

const navigateToMarketplace = () => {
  router.push({ name: 'helpforce_marketplace' });
};

const configureAgent = agent => {
  selectedAgent.value = agent;
  agentConfig.value = {
    temperature: agent.temperature || 0.7,
    max_tokens: agent.max_tokens || 2000,
    auto_respond: agent.auto_respond || false,
    custom_prompt: agent.custom_prompt || '',
    ai_provider: agent.ai_provider || 'openai',
  };
  showConfigModal.value = true;
};

const testAgent = agent => {
  selectedAgent.value = agent;
  testMessage.value = '';
  testResponse.value = '';
  testResponseTime.value = 0;
  showTestModal.value = true;
};

const toggleAgentStatus = async agent => {
  try {
    const newStatus = agent.status === 'active' ? 'inactive' : 'active';
    await updateAgent(agent.agent_id, { status: newStatus });
    agent.status = newStatus;
    showAlert(`Agent ${newStatus === 'active' ? 'activated' : 'paused'}`);
  } catch (error) {
    showAlert('Failed to update agent status');
  }
};

const saveConfiguration = async () => {
  try {
    isSaving.value = true;
    await updateAgent(selectedAgent.value.agent_id, agentConfig.value);

    // Update local agent data
    Object.assign(selectedAgent.value, agentConfig.value);

    showConfigModal.value = false;
    showAlert('Agent configuration saved');
  } catch (error) {
    showAlert('Failed to save configuration');
  } finally {
    isSaving.value = false;
  }
};

const runTest = async () => {
  if (!testMessage.value.trim()) {
    showAlert('Please enter a test message');
    return;
  }

  try {
    isTesting.value = true;
    const startTime = Date.now();

    const result = await performAgentTest(
      selectedAgent.value.agent_id,
      testMessage.value
    );

    testResponseTime.value = Date.now() - startTime;
    testResponse.value = result.response || 'Test completed successfully';

    showAlert('Agent test completed');
  } catch (error) {
    showAlert('Agent test failed');
    testResponse.value = `Test failed: ${error.message}`;
  } finally {
    isTesting.value = false;
  }
};

// Utility methods
const formatCategory = category => {
  const categoryMap = {
    technical: 'Technical Support',
    billing: 'Billing & Payments',
    sales: 'Sales & Marketing',
    onboarding: 'Customer Onboarding',
    multilingual: 'Multilingual Support',
    management: 'Escalation Management',
  };
  return categoryMap[category] || category;
};

const formatCapability = capability => {
  return capability.replace(/_/g, ' ').replace(/\b\w/g, l => l.toUpperCase());
};

const formatStatus = status => {
  return status === 'active' ? 'Active' : 'Paused';
};

const formatTime = timestamp => {
  if (!timestamp) return 'Never';

  const now = new Date();
  const time = new Date(timestamp);
  const diff = now - time;

  if (diff < 60000) return 'Just now';
  if (diff < 3600000) return `${Math.floor(diff / 60000)}m ago`;
  if (diff < 86400000) return `${Math.floor(diff / 3600000)}h ago`;
  return `${Math.floor(diff / 86400000)}d ago`;
};

const statusBadgeClass = status => {
  return status === 'active'
    ? 'bg-emerald-100 text-emerald-700'
    : 'bg-slate-100 text-slate-700';
};

// Initialize
onMounted(async () => {
  try {
    await loadInstalledAgents();

    // Check if specific agent should be configured from query params
    if (route.query.agent) {
      const agent = installedAgents.value.find(
        a => a.agent_id === route.query.agent
      );
      if (agent) {
        configureAgent(agent);
      }
    }
  } catch (error) {
    showAlert('Failed to load installed agents');
  }
});
</script>

<template>
  <div class="min-h-screen bg-slate-25">
    <!-- Header -->
    <div class="bg-white border-b border-slate-200 px-8 py-6">
      <div class="max-w-6xl mx-auto">
        <div class="flex items-center justify-between">
          <div>
            <h1 class="text-2xl font-bold text-slate-800 mb-1">
              ⚙️ AI Agent Management
            </h1>
            <p class="text-slate-600">
              Configure and monitor your installed AI agents
            </p>
          </div>
          <div class="flex items-center space-x-4">
            <woot-button
              size="small"
              variant="smooth"
              @click="navigateToMarketplace"
            >
              🛒 Browse Marketplace
            </woot-button>
            <woot-button
              size="small"
              variant="smooth"
              :is-loading="isLoading"
              @click="refreshAgents"
            >
              Refresh
            </woot-button>
          </div>
        </div>
      </div>
    </div>

    <!-- Content -->
    <div class="max-w-6xl mx-auto px-8 py-8">
      <!-- Agent Stats -->
      <div class="grid grid-cols-4 gap-6 mb-8">
        <div class="bg-white rounded-lg p-6 border border-slate-200">
          <div class="flex items-center justify-between">
            <div>
              <div class="text-2xl font-bold text-blue-600">
                {{ installedAgents.length }}
              </div>
              <div class="text-sm text-slate-600">Total Agents</div>
            </div>
            <div
              class="w-12 h-12 bg-blue-100 rounded-lg flex items-center justify-center"
            >
              🤖
            </div>
          </div>
        </div>

        <div class="bg-white rounded-lg p-6 border border-slate-200">
          <div class="flex items-center justify-between">
            <div>
              <div class="text-2xl font-bold text-emerald-600">
                {{ activeAgents }}
              </div>
              <div class="text-sm text-slate-600">Active</div>
            </div>
            <div
              class="w-12 h-12 bg-emerald-100 rounded-lg flex items-center justify-center"
            >
              ✅
            </div>
          </div>
        </div>

        <div class="bg-white rounded-lg p-6 border border-slate-200">
          <div class="flex items-center justify-between">
            <div>
              <div class="text-2xl font-bold text-purple-600">
                {{ totalConversations }}
              </div>
              <div class="text-sm text-slate-600">Conversations</div>
            </div>
            <div
              class="w-12 h-12 bg-purple-100 rounded-lg flex items-center justify-center"
            >
              💬
            </div>
          </div>
        </div>

        <div class="bg-white rounded-lg p-6 border border-slate-200">
          <div class="flex items-center justify-between">
            <div>
              <div class="text-2xl font-bold text-orange-600">
                {{ averagePerformance }}%
              </div>
              <div class="text-sm text-slate-600">Avg Performance</div>
            </div>
            <div
              class="w-12 h-12 bg-orange-100 rounded-lg flex items-center justify-center"
            >
              📊
            </div>
          </div>
        </div>
      </div>

      <!-- Agents List -->
      <div v-if="isLoading" class="space-y-4">
        <div
          v-for="i in 3"
          :key="i"
          class="bg-white rounded-lg p-6 border border-slate-200 animate-pulse"
        >
          <div class="flex items-center space-x-4">
            <div class="w-16 h-16 bg-slate-200 rounded-lg" />
            <div class="flex-1">
              <div class="h-4 bg-slate-200 rounded mb-2" />
              <div class="h-3 bg-slate-200 rounded mb-2" />
              <div class="h-3 bg-slate-200 rounded w-1/2" />
            </div>
          </div>
        </div>
      </div>

      <div v-else-if="installedAgents.length === 0" class="text-center py-12">
        <div class="text-6xl mb-4">🤖</div>
        <h3 class="text-lg font-medium text-slate-800 mb-2">
          No AI agents installed
        </h3>
        <p class="text-slate-600 mb-6">
          Install agents from the marketplace to get started
        </p>
        <woot-button @click="navigateToMarketplace">
          🛒 Browse Marketplace
        </woot-button>
      </div>

      <div v-else class="space-y-6">
        <div
          v-for="agent in installedAgents"
          :key="agent.id"
          class="bg-white rounded-lg border border-slate-200 hover:shadow-md transition-shadow"
        >
          <!-- Agent Header -->
          <div class="p-6 border-b border-slate-100">
            <div class="flex items-start justify-between">
              <div class="flex items-start space-x-4">
                <div
                  class="w-16 h-16 bg-gradient-to-br from-blue-500 to-purple-600 rounded-lg flex items-center justify-center text-2xl text-white"
                >
                  {{ agent.icon }}
                </div>
                <div>
                  <div class="flex items-center space-x-3 mb-2">
                    <h3 class="text-lg font-semibold text-slate-800">
                      {{ agent.name }}
                    </h3>
                    <span
                      :class="statusBadgeClass(agent.status)"
                      class="px-2 py-1 rounded-full text-xs font-medium"
                    >
                      {{ formatStatus(agent.status) }}
                    </span>
                    <span
                      v-if="agent.is_premium"
                      class="px-2 py-1 bg-amber-100 text-amber-700 rounded-full text-xs font-medium"
                    >
                      Premium
                    </span>
                  </div>
                  <p class="text-slate-600 mb-3">
                    {{ agent.description || 'AI agent for customer support' }}
                  </p>
                  <div
                    class="flex items-center space-x-4 text-sm text-slate-500"
                  >
                    <span>{{ formatCategory(agent.category) }}</span>
                    <span>•</span>
                    <span>{{ agent.ai_provider }} {{ agent.ai_model }}</span>
                    <span>•</span>
                    <span
                      >{{ agent.capabilities?.length || 0 }} capabilities</span
                    >
                  </div>
                </div>
              </div>
              <div class="flex items-center space-x-2">
                <woot-button
                  size="small"
                  variant="clear"
                  @click="configureAgent(agent)"
                >
                  ⚙️ Configure
                </woot-button>
                <woot-button
                  size="small"
                  variant="clear"
                  @click="testAgent(agent)"
                >
                  🧪 Test
                </woot-button>
                <woot-button
                  size="small"
                  variant="clear"
                  @click="toggleAgentStatus(agent)"
                >
                  {{ agent.status === 'active' ? '⏸️ Pause' : '▶️ Activate' }}
                </woot-button>
              </div>
            </div>
          </div>

          <!-- Agent Metrics -->
          <div class="p-6 border-b border-slate-100">
            <div class="grid grid-cols-4 gap-6">
              <div class="text-center">
                <div class="text-2xl font-bold text-blue-600">
                  {{ agent.active_conversations || 0 }}
                </div>
                <div class="text-sm text-slate-600">Active Conversations</div>
              </div>
              <div class="text-center">
                <div class="text-2xl font-bold text-emerald-600">
                  {{ agent.success_rate || 85 }}%
                </div>
                <div class="text-sm text-slate-600">Success Rate</div>
              </div>
              <div class="text-center">
                <div class="text-2xl font-bold text-purple-600">
                  {{ agent.avg_response_time || 2.3 }}s
                </div>
                <div class="text-sm text-slate-600">Avg Response Time</div>
              </div>
              <div class="text-center">
                <div class="text-2xl font-bold text-orange-600">
                  {{ agent.total_conversations || 0 }}
                </div>
                <div class="text-sm text-slate-600">Total Conversations</div>
              </div>
            </div>
          </div>

          <!-- Agent Configuration -->
          <div class="p-6">
            <div class="grid grid-cols-2 gap-6">
              <div>
                <h4 class="font-medium text-slate-800 mb-3">Configuration</h4>
                <div class="space-y-2 text-sm">
                  <div class="flex justify-between">
                    <span class="text-slate-600">Temperature:</span>
                    <span class="font-medium">{{
                      agent.temperature || 0.7
                    }}</span>
                  </div>
                  <div class="flex justify-between">
                    <span class="text-slate-600">Max Tokens:</span>
                    <span class="font-medium">{{
                      agent.max_tokens || 2000
                    }}</span>
                  </div>
                  <div class="flex justify-between">
                    <span class="text-slate-600">Auto Respond:</span>
                    <span
                      :class="
                        agent.auto_respond
                          ? 'text-emerald-600'
                          : 'text-slate-400'
                      "
                    >
                      {{ agent.auto_respond ? 'Enabled' : 'Disabled' }}
                    </span>
                  </div>
                  <div class="flex justify-between">
                    <span class="text-slate-600">Last Used:</span>
                    <span class="font-medium">{{
                      formatTime(agent.last_used_at)
                    }}</span>
                  </div>
                </div>
              </div>

              <div>
                <h4 class="font-medium text-slate-800 mb-3">Capabilities</h4>
                <div class="flex flex-wrap gap-1">
                  <span
                    v-for="capability in agent.capabilities"
                    :key="capability"
                    class="px-2 py-1 bg-blue-50 text-blue-700 rounded text-xs"
                  >
                    {{ formatCapability(capability) }}
                  </span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Agent Configuration Modal -->
    <woot-modal
      v-if="showConfigModal"
      size="large"
      @close="showConfigModal = false"
    >
      <div class="p-6">
        <h2 class="text-xl font-bold text-slate-800 mb-6">
          Configure {{ selectedAgent?.name }}
        </h2>

        <form class="space-y-6" @submit.prevent="saveConfiguration">
          <!-- Basic Settings -->
          <div class="grid grid-cols-2 gap-6">
            <div>
              <label class="block text-sm font-medium text-slate-700 mb-2">
                Temperature
              </label>
              <input
                v-model.number="agentConfig.temperature"
                type="number"
                min="0"
                max="2"
                step="0.1"
                class="w-full px-3 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500"
              />
              <p class="text-xs text-slate-500 mt-1">
                Controls randomness (0.0 = deterministic, 2.0 = very random)
              </p>
            </div>

            <div>
              <label class="block text-sm font-medium text-slate-700 mb-2">
                Max Tokens
              </label>
              <input
                v-model.number="agentConfig.max_tokens"
                type="number"
                min="100"
                max="8000"
                class="w-full px-3 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500"
              />
              <p class="text-xs text-slate-500 mt-1">
                Maximum response length in tokens
              </p>
            </div>
          </div>

          <!-- Auto Response -->
          <div>
            <label class="flex items-center">
              <input
                v-model="agentConfig.auto_respond"
                type="checkbox"
                class="rounded border-slate-300 text-blue-600 focus:ring-blue-500"
              />
              <span class="ml-2 text-sm font-medium text-slate-700">
                Enable auto-response for new conversations
              </span>
            </label>
            <p class="text-xs text-slate-500 mt-1">
              When enabled, the agent will automatically respond to new
              conversations
            </p>
          </div>

          <!-- Custom Prompt -->
          <div>
            <label class="block text-sm font-medium text-slate-700 mb-2">
              Custom System Prompt (Optional)
            </label>
            <textarea
              v-model="agentConfig.custom_prompt"
              rows="4"
              placeholder="Override the default system prompt with custom instructions..."
              class="w-full px-3 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500"
            />
          </div>

          <!-- AI Provider -->
          <div>
            <label class="block text-sm font-medium text-slate-700 mb-2">
              AI Provider
            </label>
            <select
              v-model="agentConfig.ai_provider"
              class="w-full px-3 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500"
            >
              <option value="openai">OpenAI GPT</option>
              <option value="claude">Anthropic Claude</option>
              <option value="gemini">Google Gemini</option>
            </select>
          </div>

          <div
            class="flex justify-end space-x-4 pt-4 border-t border-slate-200"
          >
            <woot-button variant="clear" @click="showConfigModal = false">
              Cancel
            </woot-button>
            <woot-button type="submit" :is-loading="isSaving">
              Save Configuration
            </woot-button>
          </div>
        </form>
      </div>
    </woot-modal>

    <!-- Agent Test Modal -->
    <woot-modal v-if="showTestModal" @close="showTestModal = false">
      <div class="p-6">
        <h2 class="text-xl font-bold text-slate-800 mb-6">
          Test {{ selectedAgent?.name }}
        </h2>

        <div class="space-y-4">
          <div>
            <label class="block text-sm font-medium text-slate-700 mb-2">
              Test Message
            </label>
            <textarea
              v-model="testMessage"
              rows="3"
              placeholder="Enter a test message to see how the agent responds..."
              class="w-full px-3 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500"
            />
          </div>

          <!-- Quick Test Templates -->
          <div>
            <label class="block text-sm font-medium text-slate-700 mb-2">
              Quick Templates
            </label>
            <div class="grid grid-cols-2 gap-2">
              <button
                v-for="template in testTemplates"
                :key="template.label"
                class="text-left p-3 border border-slate-200 rounded-lg hover:bg-slate-50 text-sm"
                @click="testMessage = template.message"
              >
                <div class="font-medium text-slate-800">
                  {{ template.label }}
                </div>
                <div class="text-slate-600">{{ template.preview }}</div>
              </button>
            </div>
          </div>

          <!-- Test Response -->
          <div
            v-if="testResponse"
            class="border border-slate-200 rounded-lg p-4"
          >
            <h4 class="font-medium text-slate-800 mb-2">Agent Response:</h4>
            <div class="text-slate-700 whitespace-pre-wrap">
              {{ testResponse }}
            </div>
            <div class="text-xs text-slate-500 mt-2">
              Response time: {{ testResponseTime }}ms
            </div>
          </div>

          <div
            class="flex justify-end space-x-4 pt-4 border-t border-slate-200"
          >
            <woot-button variant="clear" @click="showTestModal = false">
              Close
            </woot-button>
            <woot-button :is-loading="isTesting" @click="runTest">
              🧪 Run Test
            </woot-button>
          </div>
        </div>
      </div>
    </woot-modal>
  </div>
</template>
