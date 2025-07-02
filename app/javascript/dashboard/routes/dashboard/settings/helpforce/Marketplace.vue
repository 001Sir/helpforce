<script setup>
import { ref, computed, onMounted } from 'vue';
import { useRouter } from 'vue-router';
import { useAlert } from 'dashboard/composables';
import { useHelpforceMarketplace } from 'dashboard/composables/useHelpforceMarketplace';

const router = useRouter();
const { showAlert } = useAlert();

const {
  isLoading,
  marketplace,
  installedAgents,
  selectedAgent,
  filters,
  marketplaceState,
  filteredAgents,
  freeAgents,
  premiumAgents,
  loadMarketplace,
  loadInstalledAgents,
  installAgent,
  uninstallAgent,
  clearFilters,
  isAgentInstalled,
} = useHelpforceMarketplace();

// Local reactive state
const showPreviewModal = ref(false);
const showSuccessModal = ref(false);
const isInstallingAgent = ref(null);
const lastInstalledAgent = ref(null);

// Methods
const refreshMarketplace = async () => {
  try {
    await Promise.all([loadMarketplace(true), loadInstalledAgents()]);
    showAlert('Marketplace refreshed successfully');
  } catch (error) {
    showAlert('Failed to refresh marketplace');
  }
};

const previewAgent = agent => {
  selectedAgent.value = agent;
  showPreviewModal.value = true;
};

const installAgentFromPreview = async () => {
  if (!selectedAgent.value) return;

  try {
    isInstallingAgent.value = selectedAgent.value.id;
    await installAgent(selectedAgent.value.id);

    lastInstalledAgent.value = selectedAgent.value;
    showPreviewModal.value = false;
    showSuccessModal.value = true;
  } catch (error) {
    showAlert(`Failed to install agent: ${error.message}`);
  } finally {
    isInstallingAgent.value = null;
  }
};

const configureAgent = agent => {
  router.push({
    name: 'helpforce_agents',
    query: { agent: agent.id },
  });
};

const configureInstalledAgent = () => {
  showSuccessModal.value = false;
  if (lastInstalledAgent.value) {
    configureAgent(lastInstalledAgent.value);
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

const formatPricing = pricing => {
  return pricing === 'free' ? 'Free' : 'Premium';
};

const formatProvider = provider => {
  const providerMap = {
    openai: 'OpenAI GPT',
    claude: 'Anthropic Claude',
    gemini: 'Google Gemini',
  };
  return providerMap[provider] || provider;
};

const pricingBadgeClasses = pricing => {
  return pricing === 'free'
    ? 'bg-emerald-100 text-emerald-700'
    : 'bg-amber-100 text-amber-700';
};

// Initialize
onMounted(async () => {
  try {
    await Promise.all([loadMarketplace(), loadInstalledAgents()]);
  } catch (error) {
    showAlert('Failed to load marketplace');
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
              🛒 AI Agent Marketplace
            </h1>
            <p class="text-slate-600">
              Discover and install specialized AI agents for your support team
            </p>
          </div>
          <div class="flex items-center space-x-4">
            <div class="text-right">
              <div class="text-sm text-slate-500">Installed Agents</div>
              <div class="text-xl font-bold text-emerald-600">
                {{ installedAgents.length }}
              </div>
            </div>
            <woot-button
              size="small"
              variant="smooth"
              :is-loading="isLoading"
              @click="refreshMarketplace"
            >
              Refresh
            </woot-button>
          </div>
        </div>

        <!-- Search and Filters -->
        <div class="mt-6 flex items-center space-x-4">
          <div class="flex-1 relative">
            <input
              v-model="filters.search"
              type="text"
              placeholder="Search agents by name, capability, or category..."
              class="w-full pl-10 pr-4 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
            />
            <div class="absolute left-3 top-2.5 text-slate-400">🔍</div>
          </div>

          <select
            v-model="filters.category"
            class="px-4 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500"
          >
            <option value="">All Categories</option>
            <option
              v-for="category in marketplaceState.categories"
              :key="category"
              :value="category"
            >
              {{ formatCategory(category) }}
            </option>
          </select>

          <select
            v-model="filters.pricing"
            class="px-4 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500"
          >
            <option value="">All Pricing</option>
            <option value="free">Free Only</option>
            <option value="premium">Premium Only</option>
          </select>

          <woot-button size="small" variant="clear" @click="clearFilters">
            Clear Filters
          </woot-button>
        </div>
      </div>
    </div>

    <!-- Content -->
    <div class="max-w-6xl mx-auto px-8 py-8">
      <!-- Quick Stats -->
      <div class="grid grid-cols-4 gap-6 mb-8">
        <div class="bg-white rounded-lg p-4 border border-slate-200">
          <div class="text-2xl font-bold text-blue-600">
            {{ marketplaceState.totalAvailable }}
          </div>
          <div class="text-sm text-slate-600">Total Agents</div>
        </div>
        <div class="bg-white rounded-lg p-4 border border-slate-200">
          <div class="text-2xl font-bold text-emerald-600">
            {{ freeAgents.length }}
          </div>
          <div class="text-sm text-slate-600">Free Agents</div>
        </div>
        <div class="bg-white rounded-lg p-4 border border-slate-200">
          <div class="text-2xl font-bold text-amber-600">
            {{ premiumAgents.length }}
          </div>
          <div class="text-sm text-slate-600">Premium Agents</div>
        </div>
        <div class="bg-white rounded-lg p-4 border border-slate-200">
          <div class="text-2xl font-bold text-purple-600">
            {{ installedAgents.length }}
          </div>
          <div class="text-sm text-slate-600">Installed</div>
        </div>
      </div>

      <!-- Agent Grid -->
      <div v-if="isLoading" class="grid grid-cols-3 gap-6">
        <div
          v-for="i in 6"
          :key="i"
          class="bg-white rounded-lg p-6 border border-slate-200 animate-pulse"
        >
          <div class="w-12 h-12 bg-slate-200 rounded-lg mb-4" />
          <div class="h-4 bg-slate-200 rounded mb-2" />
          <div class="h-3 bg-slate-200 rounded mb-4" />
          <div class="h-8 bg-slate-200 rounded" />
        </div>
      </div>

      <div v-else-if="filteredAgents.length === 0" class="text-center py-12">
        <div class="text-6xl mb-4">🤖</div>
        <h3 class="text-lg font-medium text-slate-800 mb-2">No agents found</h3>
        <p class="text-slate-600 mb-4">
          Try adjusting your search criteria or filters
        </p>
        <woot-button size="small" @click="clearFilters">
          Clear Filters
        </woot-button>
      </div>

      <div v-else class="grid grid-cols-3 gap-6">
        <div
          v-for="agent in filteredAgents"
          :key="agent.id"
          class="bg-white rounded-lg border border-slate-200 hover:shadow-md transition-shadow"
        >
          <!-- Agent Card Header -->
          <div class="p-6 border-b border-slate-100">
            <div class="flex items-start justify-between mb-4">
              <div
                class="w-12 h-12 bg-gradient-to-br from-blue-500 to-purple-600 rounded-lg flex items-center justify-center text-2xl text-white"
              >
                {{ agent.icon }}
              </div>
              <div class="flex items-center space-x-2">
                <span
                  :class="pricingBadgeClasses(agent.pricing)"
                  class="px-2 py-1 rounded-full text-xs font-medium"
                >
                  {{ formatPricing(agent.pricing) }}
                </span>
                <span
                  v-if="isAgentInstalled(agent.id)"
                  class="px-2 py-1 bg-emerald-100 text-emerald-700 rounded-full text-xs font-medium"
                >
                  Installed
                </span>
              </div>
            </div>

            <h3 class="font-semibold text-slate-800 mb-2">{{ agent.name }}</h3>
            <p class="text-sm text-slate-600 mb-4">{{ agent.description }}</p>

            <div class="flex items-center space-x-2 mb-4">
              <span
                class="px-2 py-1 bg-slate-100 text-slate-700 rounded text-xs"
              >
                {{ formatCategory(agent.category) }}
              </span>
              <span class="text-xs text-slate-500"> v{{ agent.version }} </span>
            </div>
          </div>

          <!-- Agent Capabilities -->
          <div class="p-6 border-b border-slate-100">
            <h4 class="text-sm font-medium text-slate-800 mb-3">
              Capabilities
            </h4>
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

          <!-- Agent Actions -->
          <div class="p-6">
            <div v-if="isAgentInstalled(agent.id)" class="space-y-3">
              <woot-button
                size="small"
                variant="smooth"
                class="w-full"
                @click="configureAgent(agent)"
              >
                ⚙️ Configure
              </woot-button>
              <woot-button
                size="small"
                variant="clear"
                class="w-full"
                @click="uninstallAgent(agent)"
              >
                🗑️ Uninstall
              </woot-button>
            </div>

            <div v-else class="space-y-3">
              <woot-button
                size="small"
                variant="smooth"
                class="w-full"
                :is-loading="isInstallingAgent === agent.id"
                @click="installAgent(agent)"
              >
                💾 Install Agent
              </woot-button>
              <woot-button
                size="small"
                variant="clear"
                class="w-full"
                @click="previewAgent(agent)"
              >
                👁️ Preview
              </woot-button>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Agent Preview Modal -->
    <woot-modal v-if="showPreviewModal" @close="showPreviewModal = false">
      <div class="w-full max-w-2xl mx-auto">
        <div class="p-6">
          <div class="flex items-center space-x-4 mb-6">
            <div
              class="w-16 h-16 bg-gradient-to-br from-blue-500 to-purple-600 rounded-lg flex items-center justify-center text-2xl text-white"
            >
              {{ selectedAgent?.icon }}
            </div>
            <div>
              <h2 class="text-xl font-bold text-slate-800">
                {{ selectedAgent?.name }}
              </h2>
              <p class="text-slate-600">{{ selectedAgent?.description }}</p>
            </div>
          </div>

          <div class="space-y-6">
            <!-- Conversation Starters -->
            <div>
              <h3 class="font-medium text-slate-800 mb-3">
                Conversation Starters
              </h3>
              <div class="space-y-2">
                <div
                  v-for="starter in selectedAgent?.conversation_starters"
                  :key="starter"
                  class="p-3 bg-slate-50 rounded-lg text-sm text-slate-700"
                >
                  "{{ starter }}"
                </div>
              </div>
            </div>

            <!-- Provider Recommendations -->
            <div>
              <h3 class="font-medium text-slate-800 mb-3">
                Recommended AI Providers
              </h3>
              <div class="flex space-x-2">
                <span
                  v-for="provider in selectedAgent?.provider_recommendations"
                  :key="provider"
                  class="px-3 py-1 bg-blue-100 text-blue-700 rounded-full text-sm"
                >
                  {{ formatProvider(provider) }}
                </span>
              </div>
            </div>

            <!-- Actions -->
            <div class="flex space-x-4 pt-4">
              <woot-button
                variant="smooth"
                :is-loading="isInstallingAgent === selectedAgent?.id"
                @click="installAgentFromPreview"
              >
                💾 Install This Agent
              </woot-button>
              <woot-button variant="clear" @click="showPreviewModal = false">
                Close
              </woot-button>
            </div>
          </div>
        </div>
      </div>
    </woot-modal>

    <!-- Installation Success Modal -->
    <woot-modal v-if="showSuccessModal" @close="showSuccessModal = false">
      <div class="text-center p-8">
        <div class="text-6xl mb-4">🎉</div>
        <h2 class="text-xl font-bold text-slate-800 mb-2">
          Agent Installed Successfully!
        </h2>
        <p class="text-slate-600 mb-6">
          {{ lastInstalledAgent?.name }} is now ready to handle customer
          conversations.
        </p>
        <div class="flex space-x-4 justify-center">
          <woot-button variant="smooth" @click="configureInstalledAgent">
            ⚙️ Configure Agent
          </woot-button>
          <woot-button variant="clear" @click="showSuccessModal = false">
            Done
          </woot-button>
        </div>
      </div>
    </woot-modal>
  </div>
</template>
