<script setup>
import { ref, computed, onMounted } from 'vue';
import { useAlert } from 'dashboard/composables';
import { useHelpforceRouting } from 'dashboard/composables/useHelpforceRouting';

const { showAlert } = useAlert();

const {
  isLoading,
  routingAnalytics,
  conversationsNeedingAttention,
  agentWorkload,
  routingState,
  totalConversationsNeedingAttention,
  routingEfficiency,
  averageConfidence,
  loadRoutingAnalytics,
  loadConversationsNeedingAttention,
  loadAgentWorkload,
  routeConversation,
  routeAllUnassigned,
} = useHelpforceRouting();

// Local reactive state
const selectedTimeRange = ref('7d');
const showNeedsAttentionModal = ref(false);
const showBulkRoutingModal = ref(false);
const recentDecisions = ref([]);

// Computed properties
const routingTrends = computed(() => {
  return routingAnalytics.value.routing_trends || [];
});

const maxTrendValue = computed(() => {
  const trends = routingTrends.value;
  return trends.length > 0
    ? Math.max(...trends.map(t => t.total_assignments))
    : 100;
});

// Methods
const loadData = async () => {
  try {
    await Promise.all([
      loadRoutingAnalytics(selectedTimeRange.value),
      loadConversationsNeedingAttention(),
      loadAgentWorkload(selectedTimeRange.value),
    ]);
  } catch (error) {
    showAlert('Failed to load routing data');
  }
};

const refreshData = async () => {
  await loadData();
  showAlert('Routing data refreshed');
};

const reassignConversation = conversationId => {
  // TODO: Implement reassignment modal
  showAlert('Reassignment modal not yet implemented');
};

const reviewLowConfidence = () => {
  showBulkRoutingModal.value = false;
  showNeedsAttentionModal.value = true;
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

const formatTime = timestamp => {
  const now = new Date();
  const time = new Date(timestamp);
  const diff = now - time;

  if (diff < 60000) return 'Just now';
  if (diff < 3600000) return `${Math.floor(diff / 60000)}m ago`;
  if (diff < 86400000) return `${Math.floor(diff / 3600000)}h ago`;
  return `${Math.floor(diff / 86400000)}d ago`;
};

const formatTrendDate = date => {
  return new Date(date).toLocaleDateString('en-US', {
    month: 'short',
    day: 'numeric',
  });
};

const getConfidenceColor = confidence => {
  if (confidence >= 80) return 'bg-emerald-500';
  if (confidence >= 60) return 'bg-amber-500';
  return 'bg-red-500';
};

// Initialize
onMounted(async () => {
  await loadData();

  // Mock recent decisions for demo
  recentDecisions.value = [
    {
      id: 1,
      agent: 'Technical Support',
      conversation_id: '12345',
      confidence: 92,
      timestamp: Date.now() - 300000,
    },
    {
      id: 2,
      agent: 'Billing Support',
      conversation_id: '12346',
      confidence: 78,
      timestamp: Date.now() - 600000,
    },
    {
      id: 3,
      agent: 'Sales Assistant',
      conversation_id: '12347',
      confidence: 85,
      timestamp: Date.now() - 900000,
    },
  ];
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
              🎯 Smart Routing Dashboard
            </h1>
            <p class="text-slate-600">
              Monitor and manage intelligent conversation routing
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
            <woot-button
              size="small"
              variant="smooth"
              :is-loading="isLoading"
              @click="refreshData"
>
              Refresh
            </woot-button>
          </div>
        </div>
      </div>
    </div>

    <!-- Alert Banner -->
    <div
v-if="totalConversationsNeedingAttention > 0" 
      class="bg-amber-50 border-b border-amber-200 px-8 py-4"
    >
      <div class="max-w-6xl mx-auto">
        <div class="flex items-center justify-between">
          <div class="flex items-center space-x-3">
            <div
              class="w-8 h-8 bg-amber-100 rounded-full flex items-center justify-center"
            >
              ⚠️
            </div>
            <div>
              <div class="font-medium text-amber-800">
                {{ totalConversationsNeedingAttention }} conversations need
                attention
              </div>
              <div class="text-sm text-amber-700">
                {{
                  conversationsNeedingAttention.unassigned?.length || 0
                }}
                unassigned,
                {{
                  conversationsNeedingAttention.low_confidence?.length || 0
                }}
                low confidence,
                {{
                  conversationsNeedingAttention.long_unresolved?.length || 0
                }}
                long unresolved
              </div>
            </div>
          </div>
          <woot-button
            size="small"
            variant="smooth"
            @click="showNeedsAttentionModal = true"
          >
            Review All
          </woot-button>
        </div>
      </div>
    </div>

    <!-- Content -->
    <div class="max-w-6xl mx-auto px-8 py-8">
      <!-- Key Metrics -->
      <div class="grid grid-cols-4 gap-6 mb-8">
        <div class="bg-white rounded-lg p-6 border border-slate-200">
          <div class="flex items-center justify-between mb-4">
            <div
              class="w-12 h-12 bg-blue-100 rounded-lg flex items-center justify-center"
            >
              🎯
            </div>
            <div class="text-right">
              <div class="text-2xl font-bold text-blue-600">
                {{ routingEfficiency }}%
              </div>
              <div class="text-sm text-slate-600">Routing Efficiency</div>
            </div>
          </div>
          <div class="text-xs text-slate-500">
            {{ routingAnalytics.routing_overview?.auto_assignments || 0 }} of
            {{
              routingAnalytics.routing_overview?.total_assignments || 0
            }}
            auto-routed
          </div>
        </div>

        <div class="bg-white rounded-lg p-6 border border-slate-200">
          <div class="flex items-center justify-between mb-4">
            <div
              class="w-12 h-12 bg-emerald-100 rounded-lg flex items-center justify-center"
            >
              ⚡
            </div>
            <div class="text-right">
              <div class="text-2xl font-bold text-emerald-600">
                {{ averageConfidence }}%
              </div>
              <div class="text-sm text-slate-600">Avg Confidence</div>
            </div>
          </div>
          <div class="text-xs text-slate-500">
            High confidence routing decisions
          </div>
        </div>

        <div class="bg-white rounded-lg p-6 border border-slate-200">
          <div class="flex items-center justify-between mb-4">
            <div
              class="w-12 h-12 bg-purple-100 rounded-lg flex items-center justify-center"
            >
              📊
            </div>
            <div class="text-right">
              <div class="text-2xl font-bold text-purple-600">
                {{ routingAnalytics.success_metrics?.resolution_rate || 0 }}%
              </div>
              <div class="text-sm text-slate-600">Resolution Rate</div>
            </div>
          </div>
          <div class="text-xs text-slate-500">
            Successfully resolved conversations
          </div>
        </div>

        <div class="bg-white rounded-lg p-6 border border-slate-200">
          <div class="flex items-center justify-between mb-4">
            <div
              class="w-12 h-12 bg-orange-100 rounded-lg flex items-center justify-center"
            >
              ⏱️
            </div>
            <div class="text-right">
              <div class="text-2xl font-bold text-orange-600">
                {{
                  routingAnalytics.success_metrics?.avg_resolution_time || 0
                }}h
              </div>
              <div class="text-sm text-slate-600">Avg Resolution</div>
            </div>
          </div>
          <div class="text-xs text-slate-500">
            Time to resolve conversations
          </div>
        </div>
      </div>

      <!-- Routing Trends Chart -->
      <div class="bg-white rounded-lg border border-slate-200 p-6 mb-8">
        <h3 class="text-lg font-semibold text-slate-800 mb-4">
          Routing Trends
        </h3>
        <div
          v-if="routingTrends.length === 0"
          class="text-center py-8 text-slate-500"
        >
          No routing data available for the selected time period
        </div>
        <div v-else class="h-64 flex items-end justify-between space-x-2">
          <div
v-for="(trend, index) in routingTrends" 
            :key="index"
            class="flex-1 flex flex-col items-center"
          >
            <div
              class="w-full bg-blue-500 rounded-t transition-all"
              :style="{
                height: `${(trend.total_assignments / maxTrendValue) * 200}px`,
              }"
            />
            <div class="text-xs text-slate-500 mt-2">
              {{ formatTrendDate(trend.date) }}
            </div>
          </div>
        </div>
      </div>

      <!-- Agent Workload -->
      <div class="grid grid-cols-2 gap-8 mb-8">
        <div class="bg-white rounded-lg border border-slate-200 p-6">
          <h3 class="text-lg font-semibold text-slate-800 mb-4">
            Agent Workload
          </h3>
          <div
            v-if="agentWorkload.length === 0"
            class="text-center py-8 text-slate-500"
          >
            No agent workload data available
          </div>
          <div v-else class="space-y-4">
            <div
v-for="agent in agentWorkload.slice(0, 5)" 
              :key="agent.agent_id"
              class="flex items-center justify-between p-4 border border-slate-100 rounded-lg"
            >
              <div class="flex items-center space-x-3">
                <div
                  class="w-10 h-10 bg-gradient-to-br from-blue-500 to-purple-600 rounded-lg flex items-center justify-center text-white text-sm"
                >
                  🤖
                </div>
                <div>
                  <div class="font-medium text-slate-800">
                    {{ agent.agent_name }}
                  </div>
                  <div class="text-sm text-slate-500">
                    {{ formatCategory(agent.agent_category) }}
                  </div>
                </div>
              </div>
              <div class="text-right">
                <div class="font-medium text-slate-800">
                  {{ agent.active_assignments }}
                </div>
                <div class="text-sm text-slate-500">active</div>
              </div>
            </div>
          </div>
        </div>

        <div class="bg-white rounded-lg border border-slate-200 p-6">
          <h3 class="text-lg font-semibold text-slate-800 mb-4">
            Recent Routing Decisions
          </h3>
          <div class="space-y-4">
            <div
v-for="decision in recentDecisions" 
              :key="decision.id"
              class="flex items-center justify-between p-4 border border-slate-100 rounded-lg"
            >
              <div class="flex items-center space-x-3">
                <div
:class="getConfidenceColor(decision.confidence)" 
                  class="w-3 h-3 rounded-full"
                />
                <div>
                  <div class="font-medium text-slate-800">
                    {{ decision.agent }}
                  </div>
                  <div class="text-sm text-slate-500">
                    Conversation #{{ decision.conversation_id }}
                  </div>
                </div>
              </div>
              <div class="text-right">
                <div class="font-medium text-slate-800">
                  {{ decision.confidence }}%
                </div>
                <div class="text-sm text-slate-500">
                  {{ formatTime(decision.timestamp) }}
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Quick Actions -->
      <div class="bg-white rounded-lg border border-slate-200 p-6">
        <h3 class="text-lg font-semibold text-slate-800 mb-4">Quick Actions</h3>
        <div class="grid grid-cols-3 gap-4">
          <woot-button
            variant="smooth"
            class="h-12"
            :is-loading="routingState.bulkOperationInProgress"
            @click="routeAllUnassigned"
>
            🎯 Route All Unassigned
          </woot-button>
          <woot-button
            variant="clear"
            class="h-12"
            @click="showNeedsAttentionModal = true"
          >
            👁️ Review Problem Cases
          </woot-button>
          <woot-button
            variant="clear"
            class="h-12"
            @click="showBulkRoutingModal = true"
          >
            📦 Bulk Operations
          </woot-button>
        </div>
      </div>
    </div>

    <!-- Needs Attention Modal -->
    <woot-modal
      v-if="showNeedsAttentionModal"
      size="large"
      @close="showNeedsAttentionModal = false"
>
      <div class="p-6">
        <h2 class="text-xl font-bold text-slate-800 mb-6">
          Conversations Needing Attention
        </h2>

        <div class="space-y-6">
          <!-- Unassigned Conversations -->
          <div v-if="conversationsNeedingAttention.unassigned?.length > 0">
            <h3 class="font-medium text-slate-800 mb-3">
              Unassigned ({{ conversationsNeedingAttention.unassigned.length }})
            </h3>
            <div class="space-y-2">
              <div
v-for="conv in conversationsNeedingAttention.unassigned.slice(0, 5)" 
                   :key="conv.id"
                class="flex items-center justify-between p-4 border border-slate-200 rounded-lg"
              >
                <div>
                  <div class="font-medium text-slate-800">
                    #{{ conv.display_id }}
                  </div>
                  <div class="text-sm text-slate-500">
                    {{ conv.contact.name }} • {{ formatTime(conv.created_at) }}
                  </div>
                  <div class="text-sm text-slate-600 mt-1">
                    {{ conv.last_message }}
                  </div>
                </div>
                <woot-button
size="small"
@click="routeConversation(conv.id)"
>
                  Route Now
                </woot-button>
              </div>
            </div>
          </div>

          <!-- Low Confidence -->
          <div v-if="conversationsNeedingAttention.low_confidence?.length > 0">
            <h3 class="font-medium text-slate-800 mb-3">
              Low Confidence ({{
                conversationsNeedingAttention.low_confidence.length
              }})
            </h3>
            <div class="space-y-2">
              <div
                v-for="conv in conversationsNeedingAttention.low_confidence.slice(0, 5)" 
                :key="conv.id"
                class="flex items-center justify-between p-4 border border-slate-200 rounded-lg"
              >
                <div>
                  <div class="font-medium text-slate-800">
                    #{{ conv.display_id }}
                  </div>
                  <div class="text-sm text-slate-500">
                    {{ conv.contact.name }} •
                    {{ conv.current_assignment?.confidence_score }}% confidence
                  </div>
                  <div class="text-sm text-slate-600 mt-1">
                    {{ conv.last_message }}
                  </div>
                </div>
                <woot-button
                  size="small"
                  variant="clear"
                  @click="reassignConversation(conv.id)"
                >
                  Reassign
                </woot-button>
              </div>
            </div>
          </div>
        </div>

        <div
          class="flex justify-end space-x-4 mt-6 pt-4 border-t border-slate-200"
        >
          <woot-button
variant="clear"
@click="showNeedsAttentionModal = false"
>
            Close
          </woot-button>
        </div>
      </div>
    </woot-modal>

    <!-- Bulk Routing Modal -->
    <woot-modal
      v-if="showBulkRoutingModal"
      @close="showBulkRoutingModal = false"
    >
      <div class="p-6">
        <h2 class="text-xl font-bold text-slate-800 mb-6">
          Bulk Routing Operations
        </h2>

        <div class="space-y-4">
          <div class="p-4 border border-slate-200 rounded-lg">
            <h3 class="font-medium text-slate-800 mb-2">
              Route All Unassigned
            </h3>
            <p class="text-sm text-slate-600 mb-4">
              Automatically route all unassigned conversations using AI analysis
            </p>
            <woot-button
              :is-loading="routingState.bulkOperationInProgress"
              @click="routeAllUnassigned"
>
              Route
              {{
                conversationsNeedingAttention.unassigned?.length || 0
              }}
              Conversations
            </woot-button>
          </div>

          <div class="p-4 border border-slate-200 rounded-lg">
            <h3 class="font-medium text-slate-800 mb-2">
              Reassign Low Confidence
            </h3>
            <p class="text-sm text-slate-600 mb-4">
              Review and reassign conversations with low routing confidence
            </p>
            <woot-button
variant="clear"
@click="reviewLowConfidence"
>
              Review
              {{
                conversationsNeedingAttention.low_confidence?.length || 0
              }}
              Cases
            </woot-button>
          </div>
        </div>

        <div
          class="flex justify-end space-x-4 mt-6 pt-4 border-t border-slate-200"
        >
          <woot-button
variant="clear"
@click="showBulkRoutingModal = false"
>
            Close
          </woot-button>
        </div>
      </div>
    </woot-modal>
  </div>
</template>
