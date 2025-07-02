import { ref, computed, reactive } from 'vue';
import { useAlert } from 'dashboard/composables';
import HelpforceRoutingAPI from 'dashboard/api/helpforceRouting';

export function useHelpforceRouting() {
  const isLoading = ref(false);
  const routingAnalytics = ref({});
  const conversationsNeedingAttention = ref({});
  const agentWorkload = ref([]);
  const { showAlert } = useAlert();

  // Reactive state for routing operations
  const routingState = reactive({
    selectedConversations: [],
    bulkOperationInProgress: false,
    lastRoutingResult: null,
    autoRoutingEnabled: true,
  });

  // Computed properties
  const totalConversationsNeedingAttention = computed(() => {
    const data = conversationsNeedingAttention.value;
    return (
      (data.unassigned?.length || 0) +
      (data.low_confidence?.length || 0) +
      (data.long_unresolved?.length || 0)
    );
  });

  const routingEfficiency = computed(() => {
    const analytics = routingAnalytics.value.routing_overview || {};
    const total = analytics.total_assignments || 0;
    const auto = analytics.auto_assignments || 0;

    return total > 0 ? ((auto / total) * 100).toFixed(1) : 0;
  });

  const averageConfidence = computed(() => {
    const analytics = routingAnalytics.value.routing_overview || {};
    return analytics.average_confidence || 0;
  });

  // Core routing methods
  const loadRoutingAnalytics = async (timeRange = '7d') => {
    try {
      isLoading.value = true;
      const response = await HelpforceRoutingAPI.getAnalytics(timeRange);
      routingAnalytics.value = response.data;
      return response.data;
    } catch (error) {
      console.error('Failed to load routing analytics:', error);
      showAlert('Failed to load routing analytics');
      throw error;
    } finally {
      isLoading.value = false;
    }
  };

  const loadConversationsNeedingAttention = async () => {
    try {
      isLoading.value = true;
      const response =
        await HelpforceRoutingAPI.getConversationsNeedingAttention();
      conversationsNeedingAttention.value = response.data;
      return response.data;
    } catch (error) {
      console.error('Failed to load conversations needing attention:', error);
      showAlert('Failed to load conversations needing attention');
      throw error;
    } finally {
      isLoading.value = false;
    }
  };

  const loadAgentWorkload = async (timeRange = '7d') => {
    try {
      isLoading.value = true;
      const response = await HelpforceRoutingAPI.getAgentWorkload(timeRange);
      agentWorkload.value = response.data.agents;
      return response.data;
    } catch (error) {
      console.error('Failed to load agent workload:', error);
      showAlert('Failed to load agent workload');
      throw error;
    } finally {
      isLoading.value = false;
    }
  };

  // Conversation routing operations
  const getConversationRouting = async conversationId => {
    try {
      isLoading.value = true;
      const response =
        await HelpforceRoutingAPI.getConversationRouting(conversationId);
      return response.data;
    } catch (error) {
      console.error(
        `Failed to get routing for conversation ${conversationId}:`,
        error
      );
      showAlert('Failed to load conversation routing information');
      throw error;
    } finally {
      isLoading.value = false;
    }
  };

  const routeConversation = async conversationId => {
    try {
      isLoading.value = true;
      const response =
        await HelpforceRoutingAPI.routeConversation(conversationId);

      if (response.data.success) {
        showAlert(
          `Conversation routed to ${response.data.data.assigned_agent.name}`
        );
        routingState.lastRoutingResult = response.data;

        // Refresh conversations needing attention
        await loadConversationsNeedingAttention();

        return response.data;
      }
      showAlert(`Could not auto-route conversation: ${response.data.message}`);
      return response.data;
    } catch (error) {
      console.error(`Failed to route conversation ${conversationId}:`, error);
      showAlert('Failed to route conversation');
      throw error;
    } finally {
      isLoading.value = false;
    }
  };

  const assignAgent = async (conversationId, agentId) => {
    try {
      isLoading.value = true;
      const response = await HelpforceRoutingAPI.assignAgent(
        conversationId,
        agentId
      );

      if (response.data.success) {
        showAlert(`${response.data.data.agent.name} assigned successfully`);

        // Refresh data
        await Promise.all([
          loadConversationsNeedingAttention(),
          loadAgentWorkload(),
        ]);

        return response.data;
      }
      throw new Error(response.data.message);
    } catch (error) {
      console.error(`Failed to assign agent:`, error);
      showAlert(`Failed to assign agent: ${error.message}`);
      throw error;
    } finally {
      isLoading.value = false;
    }
  };

  const reassignAgent = async (conversationId, newAgentId, reason = '') => {
    try {
      isLoading.value = true;
      const response = await HelpforceRoutingAPI.reassignAgent(
        conversationId,
        newAgentId,
        reason
      );

      if (response.data.success) {
        showAlert(
          `Conversation reassigned to ${response.data.data.new_agent.name}`
        );

        // Refresh data
        await Promise.all([
          loadConversationsNeedingAttention(),
          loadAgentWorkload(),
        ]);

        return response.data;
      }
      throw new Error(response.data.message);
    } catch (error) {
      console.error(`Failed to reassign agent:`, error);
      showAlert(`Failed to reassign agent: ${error.message}`);
      throw error;
    } finally {
      isLoading.value = false;
    }
  };

  const unassignAgent = async (conversationId, reason = '') => {
    try {
      isLoading.value = true;
      const response = await HelpforceRoutingAPI.unassignAgent(
        conversationId,
        reason
      );

      if (response.data.success) {
        showAlert('Agent unassigned - conversation requires human attention');

        // Refresh data
        await Promise.all([
          loadConversationsNeedingAttention(),
          loadAgentWorkload(),
        ]);

        return response.data;
      }
      throw new Error(response.data.message);
    } catch (error) {
      console.error(`Failed to unassign agent:`, error);
      showAlert(`Failed to unassign agent: ${error.message}`);
      throw error;
    } finally {
      isLoading.value = false;
    }
  };

  // Bulk operations
  const bulkRouteConversations = async conversationIds => {
    try {
      routingState.bulkOperationInProgress = true;
      const response = await HelpforceRoutingAPI.bulkRoute(conversationIds);

      const { successful_routes, failed_routes, total_processed } =
        response.data;

      showAlert(
        `Bulk routing completed: ${successful_routes}/${total_processed} conversations routed successfully`
      );

      // Refresh conversations needing attention
      await loadConversationsNeedingAttention();

      return response.data;
    } catch (error) {
      console.error('Failed to bulk route conversations:', error);
      showAlert('Failed to bulk route conversations');
      throw error;
    } finally {
      routingState.bulkOperationInProgress = false;
    }
  };

  const routeAllUnassigned = async () => {
    const unassigned = conversationsNeedingAttention.value.unassigned || [];
    const conversationIds = unassigned.map(conv => conv.id);

    if (conversationIds.length === 0) {
      showAlert('No unassigned conversations to route');
      return;
    }

    return bulkRouteConversations(conversationIds);
  };

  // Utility methods
  const toggleConversationSelection = conversationId => {
    const index = routingState.selectedConversations.indexOf(conversationId);
    if (index > -1) {
      routingState.selectedConversations.splice(index, 1);
    } else {
      routingState.selectedConversations.push(conversationId);
    }
  };

  const selectAllConversations = conversations => {
    routingState.selectedConversations = conversations.map(conv => conv.id);
  };

  const clearSelection = () => {
    routingState.selectedConversations = [];
  };

  const isConversationSelected = conversationId => {
    return routingState.selectedConversations.includes(conversationId);
  };

  // Routing recommendations
  const getRoutingRecommendations = conversation => {
    // Simple client-side routing recommendations based on content
    const content = conversation.last_message?.toLowerCase() || '';
    const recommendations = [];

    if (
      content.includes('error') ||
      content.includes('bug') ||
      content.includes('problem')
    ) {
      recommendations.push({
        agent_type: 'technical_support',
        confidence: 80,
        reason: 'Technical issue detected',
      });
    }

    if (
      content.includes('bill') ||
      content.includes('payment') ||
      content.includes('refund')
    ) {
      recommendations.push({
        agent_type: 'billing_support',
        confidence: 85,
        reason: 'Billing inquiry detected',
      });
    }

    if (
      content.includes('demo') ||
      content.includes('trial') ||
      content.includes('purchase')
    ) {
      recommendations.push({
        agent_type: 'sales_assistant',
        confidence: 75,
        reason: 'Sales opportunity detected',
      });
    }

    return recommendations;
  };

  // Performance metrics
  const calculateRoutingPerformance = () => {
    const analytics = routingAnalytics.value;

    if (!analytics.routing_overview) return {};

    const overview = analytics.routing_overview;
    const success = analytics.success_metrics || {};

    return {
      efficiency: routingEfficiency.value,
      confidence: averageConfidence.value,
      resolutionRate: success.resolution_rate || 0,
      avgResolutionTime: success.avg_resolution_time || 0,
      autoRoutingRate:
        overview.auto_assignments && overview.total_assignments
          ? (
              (overview.auto_assignments / overview.total_assignments) *
              100
            ).toFixed(1)
          : 0,
    };
  };

  // Agent performance analysis
  const getTopPerformingAgents = () => {
    return agentWorkload.value
      .filter(agent => agent.total_assignments > 0)
      .sort((a, b) => {
        // Sort by confidence score and assignment success
        const aScore =
          (a.confidence_distribution?.high || 0) / (a.total_assignments || 1);
        const bScore =
          (b.confidence_distribution?.high || 0) / (b.total_assignments || 1);
        return bScore - aScore;
      })
      .slice(0, 5);
  };

  const getUnderperformingAgents = () => {
    return agentWorkload.value
      .filter(agent => agent.total_assignments > 5) // Only consider agents with meaningful data
      .filter(agent => {
        const highConfidenceRate =
          (agent.confidence_distribution?.high || 0) /
          (agent.total_assignments || 1);
        return highConfidenceRate < 0.3; // Less than 30% high confidence assignments
      });
  };

  // Initialize
  const initialize = async (timeRange = '7d') => {
    await Promise.all([
      loadRoutingAnalytics(timeRange),
      loadConversationsNeedingAttention(),
      loadAgentWorkload(timeRange),
    ]);
  };

  return {
    // State
    isLoading,
    routingAnalytics,
    conversationsNeedingAttention,
    agentWorkload,
    routingState,

    // Computed
    totalConversationsNeedingAttention,
    routingEfficiency,
    averageConfidence,

    // Core methods
    loadRoutingAnalytics,
    loadConversationsNeedingAttention,
    loadAgentWorkload,
    getConversationRouting,
    routeConversation,
    assignAgent,
    reassignAgent,
    unassignAgent,

    // Bulk operations
    bulkRouteConversations,
    routeAllUnassigned,

    // Selection management
    toggleConversationSelection,
    selectAllConversations,
    clearSelection,
    isConversationSelected,

    // Utilities
    getRoutingRecommendations,
    calculateRoutingPerformance,
    getTopPerformingAgents,
    getUnderperformingAgents,

    // Initialize
    initialize,
  };
}
