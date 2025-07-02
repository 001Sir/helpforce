<script setup>
import { ref, computed, onMounted } from 'vue';
import { useAlert } from 'dashboard/composables';
import { useHelpforceMarketplace } from 'dashboard/composables/useHelpforceMarketplace';
import { useHelpforceRouting } from 'dashboard/composables/useHelpforceRouting';

const { showAlert } = useAlert();

const { installedAgents, loadInstalledAgents } = useHelpforceMarketplace();
const {
  routingAnalytics,
  agentWorkload,
  loadRoutingAnalytics,
  loadAgentWorkload,
} = useHelpforceRouting();

// Local reactive state
const selectedTimeRange = ref('7d');
const conversationTrends = ref([]);
const recentActivity = ref([]);

// Mock data for demo
const mockData = ref({
  totalConversations: 1247,
  autoRouted: 87,
  avgResponseTime: 2.3,
  responseTimeImprovement: 15,
  satisfactionScore: 92,
  totalFeedback: 156,
});

// Computed properties
const totalAgents = computed(() => installedAgents.value.length);
const premiumAgents = computed(
  () => installedAgents.value.filter(a => a.is_premium).length
);
const freeAgents = computed(
  () => installedAgents.value.filter(a => !a.is_premium).length
);

const totalConversations = computed(() => mockData.value.totalConversations);
const autoRouted = computed(() => mockData.value.autoRouted);
const avgResponseTime = computed(() => mockData.value.avgResponseTime);
const responseTimeImprovement = computed(
  () => mockData.value.responseTimeImprovement
);
const satisfactionScore = computed(() => mockData.value.satisfactionScore);
const totalFeedback = computed(() => mockData.value.totalFeedback);

const agentPerformance = computed(() => {
  return agentWorkload.value.map(agent => ({
    agent_id: agent.agent_id,
    agent_name: agent.agent_name,
    total_assignments: agent.total_assignments || 0,
    avg_confidence: Math.round(agent.confidence_distribution?.high || 0),
  }));
});

const maxConversations = computed(() => {
  return conversationTrends.value.length > 0
    ? Math.max(...conversationTrends.value.map(t => t.conversations))
    : 100;
});

const topPerformers = computed(() => {
  return installedAgents.value
    .map(agent => ({
      id: agent.id,
      name: agent.name,
      category: agent.category,
      score: agent.success_rate || Math.floor(Math.random() * 30) + 70,
    }))
    .sort((a, b) => b.score - a.score)
    .slice(0, 5);
});

// Methods
const loadData = async () => {
  try {
    await Promise.all([
      loadInstalledAgents(),
      loadRoutingAnalytics(selectedTimeRange.value),
      loadAgentWorkload(selectedTimeRange.value),
    ]);

    // Generate mock conversation trends
    generateMockTrends();
    generateMockActivity();
  } catch (error) {
    showAlert('Failed to load analytics data');
  }
};

const generateMockTrends = () => {
  const days =
    selectedTimeRange.value === '1d'
      ? 1
      : selectedTimeRange.value === '7d'
        ? 7
        : 30;

  conversationTrends.value = Array.from({ length: days }, (_, i) => {
    const date = new Date();
    date.setDate(date.getDate() - (days - 1 - i));
    return {
      date: date.toISOString(),
      conversations: Math.floor(Math.random() * 100) + 50,
    };
  });
};

const generateMockActivity = () => {
  recentActivity.value = [
    {
      id: 1,
      icon: '🤖',
      title: 'New agent installed',
      description: 'Technical Support Specialist activated',
      timestamp: Date.now() - 300000,
    },
    {
      id: 2,
      icon: '🎯',
      title: 'High confidence routing',
      description: '95% confidence match for billing inquiry',
      timestamp: Date.now() - 600000,
    },
    {
      id: 3,
      icon: '📊',
      title: 'Performance milestone',
      description: '1000 conversations successfully routed',
      timestamp: Date.now() - 900000,
    },
    {
      id: 4,
      icon: '⚡',
      title: 'Response time improved',
      description: 'Average response time reduced to 2.1s',
      timestamp: Date.now() - 1200000,
    },
  ];
};

const exportData = () => {
  // TODO: Implement data export
  showAlert('Export functionality coming soon');
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

const formatDate = dateString => {
  return new Date(dateString).toLocaleDateString();
};

const formatTrendDate = dateString => {
  const date = new Date(dateString);
  return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
};

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
  await loadData();
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
              📊 Performance Analytics
            </h1>
            <p class="text-slate-600">
              Deep insights into AI agent performance and routing efficiency
            </p>
          </div>
          <div class="flex items-center space-x-4">
            <select
              v-model="selectedTimeRange"
              class="px-4 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500"
              @change="loadData"
            >
              <option value="1d">Last 24 Hours</option>
              <option value="7d">Last 7 Days</option>
              <option value="30d">Last 30 Days</option>
            </select>
            <woot-button size="small" variant="smooth" @click="exportData">
              📤 Export
            </woot-button>
          </div>
        </div>
      </div>
    </div>

    <!-- Content -->
    <div class="max-w-6xl mx-auto px-8 py-8">
      <!-- Overview Cards -->
      <div class="grid grid-cols-4 gap-6 mb-8">
        <div class="bg-white rounded-lg p-6 border border-slate-200">
          <div class="flex items-center justify-between mb-4">
            <div
              class="w-12 h-12 bg-blue-100 rounded-lg flex items-center justify-center"
            >
              🤖
            </div>
            <div class="text-right">
              <div class="text-2xl font-bold text-blue-600">
                {{ totalAgents }}
              </div>
              <div class="text-sm text-slate-600">Active Agents</div>
            </div>
          </div>
          <div class="text-xs text-slate-500">
            {{ premiumAgents }} premium, {{ freeAgents }} free
          </div>
        </div>

        <div class="bg-white rounded-lg p-6 border border-slate-200">
          <div class="flex items-center justify-between mb-4">
            <div
              class="w-12 h-12 bg-emerald-100 rounded-lg flex items-center justify-center"
            >
              💬
            </div>
            <div class="text-right">
              <div class="text-2xl font-bold text-emerald-600">
                {{ totalConversations }}
              </div>
              <div class="text-sm text-slate-600">Conversations</div>
            </div>
          </div>
          <div class="text-xs text-slate-500">
            {{ autoRouted }}% auto-routed
          </div>
        </div>

        <div class="bg-white rounded-lg p-6 border border-slate-200">
          <div class="flex items-center justify-between mb-4">
            <div
              class="w-12 h-12 bg-purple-100 rounded-lg flex items-center justify-center"
            >
              ⚡
            </div>
            <div class="text-right">
              <div class="text-2xl font-bold text-purple-600">
                {{ avgResponseTime }}s
              </div>
              <div class="text-sm text-slate-600">Avg Response</div>
            </div>
          </div>
          <div class="text-xs text-slate-500">
            {{ responseTimeImprovement }}% improvement
          </div>
        </div>

        <div class="bg-white rounded-lg p-6 border border-slate-200">
          <div class="flex items-center justify-between mb-4">
            <div
              class="w-12 h-12 bg-orange-100 rounded-lg flex items-center justify-center"
            >
              😊
            </div>
            <div class="text-right">
              <div class="text-2xl font-bold text-orange-600">
                {{ satisfactionScore }}%
              </div>
              <div class="text-sm text-slate-600">Satisfaction</div>
            </div>
          </div>
          <div class="text-xs text-slate-500">
            Based on {{ totalFeedback }} responses
          </div>
        </div>
      </div>

      <!-- Charts Row -->
      <div class="grid grid-cols-2 gap-8 mb-8">
        <!-- Conversation Volume Chart -->
        <div class="bg-white rounded-lg border border-slate-200 p-6">
          <h3 class="text-lg font-semibold text-slate-800 mb-4">
            Conversation Volume
          </h3>
          <div
            v-if="conversationTrends.length === 0"
            class="text-center py-8 text-slate-500"
          >
            No data available for selected period
          </div>
          <div v-else class="h-64 flex items-end justify-between space-x-1">
            <div
              v-for="(trend, index) in conversationTrends"
              :key="index"
              class="flex-1 flex flex-col items-center"
            >
              <div
                class="w-full bg-blue-500 rounded-t transition-all hover:bg-blue-600"
                :style="{
                  height: `${(trend.conversations / maxConversations) * 200}px`,
                }"
                :title="`${trend.conversations} conversations on ${formatDate(trend.date)}`"
              >
                >
              </div>
              <div class="text-xs text-slate-500 mt-2">
                {{ formatTrendDate(trend.date) }}
              </div>
            </div>
          </div>
        </div>

        <!-- Agent Performance Chart -->
        <div class="bg-white rounded-lg border border-slate-200 p-6">
          <h3 class="text-lg font-semibold text-slate-800 mb-4">
            Agent Performance
          </h3>
          <div
            v-if="agentPerformance.length === 0"
            class="text-center py-8 text-slate-500"
          >
            No agent performance data available
          </div>
          <div v-else class="space-y-4">
            <div
              v-for="agent in agentPerformance.slice(0, 5)"
              :key="agent.agent_id"
              class="flex items-center justify-between"
            >
              <div class="flex items-center space-x-3">
                <div
                  class="w-8 h-8 bg-gradient-to-br from-blue-500 to-purple-600 rounded-lg flex items-center justify-center text-white text-xs"
                >
                  🤖
                </div>
                <div>
                  <div class="font-medium text-slate-800">
                    {{ agent.agent_name }}
                  </div>
                  <div class="text-sm text-slate-500">
                    {{ agent.total_assignments }} assignments
                  </div>
                </div>
              </div>
              <div class="flex items-center space-x-4">
                <div class="text-right">
                  <div class="font-medium text-slate-800">
                    {{ agent.avg_confidence }}%
                  </div>
                  <div class="text-xs text-slate-500">confidence</div>
                </div>
                <div class="w-16 bg-slate-200 rounded-full h-2">
                  <div
                    class="bg-emerald-500 h-2 rounded-full transition-all"
                    :style="{ width: `${agent.avg_confidence}%` }"
                  >
                    >
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Detailed Tables -->
      <div class="grid grid-cols-2 gap-8">
        <!-- Top Performing Agents -->
        <div class="bg-white rounded-lg border border-slate-200">
          <div class="p-6 border-b border-slate-200">
            <h3 class="text-lg font-semibold text-slate-800">
              Top Performing Agents
            </h3>
          </div>
          <div class="p-6">
            <div
              v-if="topPerformers.length === 0"
              class="text-center py-8 text-slate-500"
            >
              No performance data available
            </div>
            <div v-else class="space-y-4">
              <div
                v-for="(agent, index) in topPerformers"
                :key="agent.id"
                class="flex items-center space-x-4 p-4 rounded-lg border border-slate-100"
              >
                <div
                  class="w-8 h-8 bg-gradient-to-br from-emerald-500 to-teal-600 rounded-lg flex items-center justify-center text-white text-sm font-bold"
                >
                  {{ index + 1 }}
                </div>
                <div class="flex-1">
                  <div class="font-medium text-slate-800">{{ agent.name }}</div>
                  <div class="text-sm text-slate-500">
                    {{ formatCategory(agent.category) }}
                  </div>
                </div>
                <div class="text-right">
                  <div class="font-bold text-emerald-600">
                    {{ agent.score }}%
                  </div>
                  <div class="text-xs text-slate-500">performance</div>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Recent Activity -->
        <div class="bg-white rounded-lg border border-slate-200">
          <div class="p-6 border-b border-slate-200">
            <h3 class="text-lg font-semibold text-slate-800">
              Recent Activity
            </h3>
          </div>
          <div class="p-6">
            <div class="space-y-4">
              <div
                v-for="activity in recentActivity"
                :key="activity.id"
                class="flex items-center space-x-4 p-4 rounded-lg border border-slate-100"
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
  </div>
</template>
