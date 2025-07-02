<script setup>
import { ref, onMounted, computed } from 'vue';
import { useRouter } from 'vue-router';
import { useHelpforceMarketplace } from 'dashboard/composables/useHelpforceMarketplace';
import { useHelpforceRouting } from 'dashboard/composables/useHelpforceRouting';

const router = useRouter();
const {
  marketplace,
  installedAgents,
  marketplaceState,
  loadMarketplace,
  loadInstalledAgents,
} = useHelpforceMarketplace();

const {
  routingAnalytics,
  conversationsNeedingAttention,
  loadRoutingAnalytics,
  loadConversationsNeedingAttention,
} = useHelpforceRouting();

// Reactive data
const recentActivity = ref([]);

// Computed properties
const agentCount = computed(() => installedAgents.value.length);
const activeConversations = computed(
  () => routingAnalytics.value.routing_overview?.active_assignments || 0
);

const marketplaceStats = computed(() => ({
  totalAgents: marketplaceState.totalAvailable || 6,
  freeAgents: 3,
  premiumAgents: 3,
  installed: installedAgents.value.length,
  categories: marketplaceState.categories?.length || 6,
}));

const routingStats = computed(() => {
  const overview = routingAnalytics.value.routing_overview || {};
  const success = routingAnalytics.value.success_metrics || {};
  const conversations = conversationsNeedingAttention.value || {};

  return {
    autoRouted:
      overview.auto_assignments && overview.total_assignments
        ? Math.round(
            (overview.auto_assignments / overview.total_assignments) * 100
          )
        : 85,
    avgResponseTime: success.avg_resolution_time || 2.5,
    satisfaction: 92,
    needsAttention:
      (conversations.unassigned?.length || 0) +
      (conversations.low_confidence?.length || 0) +
      (conversations.long_unresolved?.length || 0),
    totalRouted: overview.total_assignments || 0,
    efficiency: overview.average_confidence || 85,
  };
});

const agentStats = computed(() => ({
  active: installedAgents.value.filter(agent => agent.status === 'active')
    .length,
  conversations: installedAgents.value.reduce(
    (sum, agent) => sum + (agent.active_conversations || 0),
    0
  ),
  avgScore: 88,
}));

const analyticsStats = computed(() => ({
  trend: '↗ Improving',
  totalMetrics: '12.5K',
}));

// Navigation methods
const navigateToMarketplace = () => {
  router.push({ name: 'helpforce_marketplace' });
};

const navigateToRouting = () => {
  router.push({ name: 'helpforce_routing' });
};

const navigateToAgents = () => {
  router.push({ name: 'helpforce_agents' });
};

const navigateToAnalytics = () => {
  router.push({ name: 'helpforce_analytics' });
};

// Utility methods
const formatTime = timestamp => {
  const now = new Date();
  const time = new Date(timestamp);
  const diff = now - time;

  if (diff < 60000) return 'Just now';
  if (diff < 3600000) return `${Math.floor(diff / 60000)}m ago`;
  if (diff < 86400000) return `${Math.floor(diff / 3600000)}h ago`;
  return `${Math.floor(diff / 86400000)}d ago`;
};

// Initialize
onMounted(async () => {
  try {
    await Promise.all([
      loadMarketplace(),
      loadInstalledAgents(),
      loadRoutingAnalytics(),
      loadConversationsNeedingAttention(),
    ]);

    // Mock recent activity for now
    recentActivity.value = [
      {
        id: 1,
        icon: '🤖',
        title: 'Technical Support Agent Installed',
        description: 'Agent is now handling technical support conversations',
        timestamp: Date.now() - 300000,
      },
      {
        id: 2,
        icon: '🎯',
        title: 'Smart Routing Activated',
        description: 'Auto-routing enabled for new conversations',
        timestamp: Date.now() - 600000,
      },
    ];
  } catch (error) {
    console.error('Failed to load HelpForce dashboard:', error);
  }
});
</script>

<template>
  <div class="min-h-screen bg-slate-25 p-8">
    <div class="max-w-6xl mx-auto">
      <!-- Header -->
      <div class="mb-8">
        <div class="flex items-center justify-between">
          <div>
            <h1 class="text-3xl font-bold text-slate-800 mb-2">
              🚀 HelpForce AI Platform
            </h1>
            <p class="text-slate-600 text-lg">
              Supercharge your customer support with AI-powered agents and smart
              routing
            </p>
          </div>
          <div class="text-right">
            <div class="text-2xl font-bold text-emerald-600">
              {{ agentCount }} AI Agents
            </div>
            <div class="text-sm text-slate-500">
              {{ activeConversations }} active conversations
            </div>
          </div>
        </div>
      </div>

      <!-- Quick Stats -->
      <div class="grid grid-cols-4 gap-6 mb-8">
        <div class="bg-white rounded-lg p-6 shadow-sm border border-slate-200">
          <div class="flex items-center justify-between">
            <div>
              <div class="text-2xl font-bold text-blue-600">
                {{ marketplaceStats.totalAgents }}
              </div>
              <div class="text-sm text-slate-600">Available Agents</div>
            </div>
            <div
              class="w-12 h-12 bg-blue-100 rounded-lg flex items-center justify-center"
            >
              🤖
            </div>
          </div>
        </div>

        <div class="bg-white rounded-lg p-6 shadow-sm border border-slate-200">
          <div class="flex items-center justify-between">
            <div>
              <div class="text-2xl font-bold text-emerald-600">
                {{ routingStats.autoRouted }}%
              </div>
              <div class="text-sm text-slate-600">Auto-routed</div>
            </div>
            <div
              class="w-12 h-12 bg-emerald-100 rounded-lg flex items-center justify-center"
            >
              🎯
            </div>
          </div>
        </div>

        <div class="bg-white rounded-lg p-6 shadow-sm border border-slate-200">
          <div class="flex items-center justify-between">
            <div>
              <div class="text-2xl font-bold text-purple-600">
                {{ routingStats.avgResponseTime }}s
              </div>
              <div class="text-sm text-slate-600">Avg Response</div>
            </div>
            <div
              class="w-12 h-12 bg-purple-100 rounded-lg flex items-center justify-center"
            >
              ⚡
            </div>
          </div>
        </div>

        <div class="bg-white rounded-lg p-6 shadow-sm border border-slate-200">
          <div class="flex items-center justify-between">
            <div>
              <div class="text-2xl font-bold text-orange-600">
                {{ routingStats.satisfaction }}%
              </div>
              <div class="text-sm text-slate-600">Satisfaction</div>
            </div>
            <div
              class="w-12 h-12 bg-orange-100 rounded-lg flex items-center justify-center"
            >
              😊
            </div>
          </div>
        </div>
      </div>

      <!-- Navigation Cards -->
      <div class="grid grid-cols-2 gap-8">
        <!-- Marketplace Card -->
        <div
          class="bg-white rounded-xl p-8 shadow-sm border border-slate-200 hover:shadow-md transition-shadow cursor-pointer"
          @click="navigateToMarketplace"
        >
          <div class="flex items-start justify-between mb-6">
            <div
              class="w-16 h-16 bg-gradient-to-br from-blue-500 to-purple-600 rounded-xl flex items-center justify-center text-2xl text-white"
            >
              🛒
            </div>
            <div class="flex items-center space-x-2">
              <span
                class="px-3 py-1 bg-emerald-100 text-emerald-700 rounded-full text-sm font-medium"
              >
                {{ marketplaceStats.freeAgents }} Free
              </span>
              <span
                class="px-3 py-1 bg-amber-100 text-amber-700 rounded-full text-sm font-medium"
              >
                {{ marketplaceStats.premiumAgents }} Premium
              </span>
            </div>
          </div>
          <h3 class="text-xl font-bold text-slate-800 mb-3">
            AI Agent Marketplace
          </h3>
          <p class="text-slate-600 mb-6">
            Browse and install specialized AI agents for technical support,
            billing, sales, and more. Choose from free and premium agents
            tailored to your needs.
          </p>
          <div class="flex items-center justify-between">
            <div class="flex items-center space-x-4 text-sm text-slate-500">
              <span>{{ marketplaceStats.installed }} installed</span>
              <span>{{ marketplaceStats.categories }} categories</span>
            </div>
            <woot-button size="small" variant="smooth">
              Browse Marketplace →
            </woot-button>
          </div>
        </div>

        <!-- Smart Routing Card -->
        <div
          class="bg-white rounded-xl p-8 shadow-sm border border-slate-200 hover:shadow-md transition-shadow cursor-pointer"
          @click="navigateToRouting"
        >
          <div class="flex items-start justify-between mb-6">
            <div
              class="w-16 h-16 bg-gradient-to-br from-emerald-500 to-teal-600 rounded-xl flex items-center justify-center text-2xl text-white"
            >
              🎯
            </div>
            <div class="flex items-center space-x-2">
              <span
                v-if="routingStats.needsAttention > 0"
                class="px-3 py-1 bg-red-100 text-red-700 rounded-full text-sm font-medium"
              >
                {{ routingStats.needsAttention }} Need Attention
              </span>
              <span
                v-else
                class="px-3 py-1 bg-emerald-100 text-emerald-700 rounded-full text-sm font-medium"
              >
                All Good
              </span>
            </div>
          </div>
          <h3 class="text-xl font-bold text-slate-800 mb-3">Smart Routing</h3>
          <p class="text-slate-600 mb-6">
            Intelligent conversation routing powered by AI analysis.
            Automatically match customers with the best agents based on content,
            urgency, and expertise.
          </p>
          <div class="flex items-center justify-between">
            <div class="flex items-center space-x-4 text-sm text-slate-500">
              <span>{{ routingStats.totalRouted }} routed today</span>
              <span>{{ routingStats.efficiency }}% efficient</span>
            </div>
            <woot-button size="small" variant="smooth">
              View Dashboard →
            </woot-button>
          </div>
        </div>

        <!-- Agents Management Card -->
        <div
          class="bg-white rounded-xl p-8 shadow-sm border border-slate-200 hover:shadow-md transition-shadow cursor-pointer"
          @click="navigateToAgents"
        >
          <div class="flex items-start justify-between mb-6">
            <div
              class="w-16 h-16 bg-gradient-to-br from-purple-500 to-pink-600 rounded-xl flex items-center justify-center text-2xl text-white"
            >
              ⚙️
            </div>
            <div class="flex items-center space-x-2">
              <span
                class="px-3 py-1 bg-blue-100 text-blue-700 rounded-full text-sm font-medium"
              >
                {{ agentStats.active }} Active
              </span>
            </div>
          </div>
          <h3 class="text-xl font-bold text-slate-800 mb-3">
            Agent Management
          </h3>
          <p class="text-slate-600 mb-6">
            Configure and monitor your AI agents. Adjust settings, view
            performance metrics, and optimize agent behavior for better customer
            experiences.
          </p>
          <div class="flex items-center justify-between">
            <div class="flex items-center space-x-4 text-sm text-slate-500">
              <span>{{ agentStats.conversations }} conversations</span>
              <span>{{ agentStats.avgScore }}% score</span>
            </div>
            <woot-button size="small" variant="smooth">
              Manage Agents →
            </woot-button>
          </div>
        </div>

        <!-- Analytics Card -->
        <div
          class="bg-white rounded-xl p-8 shadow-sm border border-slate-200 hover:shadow-md transition-shadow cursor-pointer"
          @click="navigateToAnalytics"
        >
          <div class="flex items-start justify-between mb-6">
            <div
              class="w-16 h-16 bg-gradient-to-br from-orange-500 to-red-600 rounded-xl flex items-center justify-center text-2xl text-white"
            >
              📊
            </div>
            <div class="flex items-center space-x-2">
              <span
                class="px-3 py-1 bg-green-100 text-green-700 rounded-full text-sm font-medium"
              >
                {{ analyticsStats.trend }}
              </span>
            </div>
          </div>
          <h3 class="text-xl font-bold text-slate-800 mb-3">
            Performance Analytics
          </h3>
          <p class="text-slate-600 mb-6">
            Deep insights into AI agent performance, routing efficiency, and
            customer satisfaction. Track metrics and optimize your support
            operations.
          </p>
          <div class="flex items-center justify-between">
            <div class="flex items-center space-x-4 text-sm text-slate-500">
              <span>{{ analyticsStats.totalMetrics }} data points</span>
              <span>Real-time updates</span>
            </div>
            <woot-button size="small" variant="smooth">
              View Analytics →
            </woot-button>
          </div>
        </div>
      </div>

      <!-- Recent Activity -->
      <div class="mt-12 bg-white rounded-xl shadow-sm border border-slate-200">
        <div class="p-6 border-b border-slate-200">
          <h3 class="text-lg font-semibold text-slate-800">Recent Activity</h3>
        </div>
        <div class="p-6">
          <div
            v-if="recentActivity.length === 0"
            class="text-center py-8 text-slate-500"
          >
            No recent activity. Start by installing AI agents from the
            marketplace.
          </div>
          <div v-else class="space-y-4">
            <div
              v-for="activity in recentActivity"
              :key="activity.id"
              class="flex items-center space-x-4 p-4 rounded-lg border border-slate-100 hover:bg-slate-50"
            >
              <div
                class="w-8 h-8 bg-blue-100 rounded-full flex items-center justify-center text-sm"
              >
                {{ activity.icon }}
              </div>
              <div class="flex-1">
                <div class="font-medium text-slate-800">
                  {{ activity.title }}
                </div>
                <div class="text-sm text-slate-500">
                  {{ activity.description }}
                </div>
              </div>
              <div class="text-xs text-slate-400">
                {{ formatTime(activity.timestamp) }}
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
