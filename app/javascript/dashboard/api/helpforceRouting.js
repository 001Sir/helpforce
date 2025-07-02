import ApiClient from './ApiClient';

class HelpforceRoutingAPI extends ApiClient {
  constructor() {
    super('helpforce_routing', { accountScoped: true });
  }

  // Analytics and overview
  getAnalytics(timeRange = '7d') {
    return this.get('analytics', { time_range: timeRange });
  }

  getConversationsNeedingAttention() {
    return this.get('needs_attention');
  }

  getAgentWorkload(timeRange = '7d') {
    return this.get('agent_workload', { time_range: timeRange });
  }

  // Conversation-specific routing
  getConversationRouting(conversationId) {
    return this.get(`conversations/${conversationId}`);
  }

  routeConversation(conversationId) {
    return this.post(`conversations/${conversationId}/route`);
  }

  assignAgent(conversationId, agentId) {
    return this.post(`conversations/${conversationId}/assign`, {
      agent_id: agentId,
    });
  }

  reassignAgent(conversationId, newAgentId, reason = '') {
    return this.post(`conversations/${conversationId}/reassign`, {
      agent_id: newAgentId,
      reason: reason,
    });
  }

  unassignAgent(conversationId, reason = '') {
    return this.delete(`conversations/${conversationId}/assign`, {
      reason: reason,
    });
  }

  // Bulk operations
  bulkRoute(conversationIds) {
    return this.post('bulk_route', {
      conversation_ids: conversationIds,
    });
  }

  // Helper methods for routing insights
  getRoutingInsights(timeRange = '7d') {
    return Promise.all([
      this.getAnalytics(timeRange),
      this.getConversationsNeedingAttention(),
      this.getAgentWorkload(timeRange),
    ]).then(([analytics, conversations, workload]) => ({
      analytics: analytics.data,
      conversations: conversations.data,
      workload: workload.data,
    }));
  }

  // Routing performance metrics
  async getRoutingPerformanceMetrics(timeRange = '7d') {
    const analytics = await this.getAnalytics(timeRange);
    const data = analytics.data;

    const overview = data.routing_overview || {};
    const success = data.success_metrics || {};
    const trends = data.routing_trends || [];

    return {
      overview: {
        totalAssignments: overview.total_assignments || 0,
        autoAssignments: overview.auto_assignments || 0,
        manualAssignments: overview.manual_assignments || 0,
        averageConfidence: overview.average_confidence || 0,
        activeAssignments: overview.active_assignments || 0,
      },
      performance: {
        resolutionRate: success.resolution_rate || 0,
        avgResolutionTime: success.avg_resolution_time || 0,
        highConfidenceSuccessRate: success.high_confidence_success_rate || 0,
      },
      trends: trends.map(trend => ({
        date: trend.date,
        totalAssignments: trend.total_assignments,
        autoAssignments: trend.auto_assignments,
        avgConfidence: trend.avg_confidence,
      })),
      efficiency: {
        autoRoutingRate:
          overview.total_assignments > 0
            ? (
                (overview.auto_assignments / overview.total_assignments) *
                100
              ).toFixed(1)
            : 0,
        confidenceScore: overview.average_confidence || 0,
      },
    };
  }

  // Agent-specific routing analytics
  async getAgentRoutingAnalytics(agentId, timeRange = '7d') {
    const workload = await this.getAgentWorkload(timeRange);
    const agent = workload.data.agents.find(a => a.agent_id === agentId);

    if (!agent) {
      throw new Error(`Agent ${agentId} not found in workload data`);
    }

    return {
      agent: {
        id: agent.agent_id,
        name: agent.agent_name,
        category: agent.agent_category,
      },
      assignments: {
        total: agent.total_assignments,
        active: agent.active_assignments,
        averageDuration: agent.average_assignment_duration,
      },
      confidence: {
        high: agent.confidence_distribution?.high || 0,
        medium: agent.confidence_distribution?.medium || 0,
        low: agent.confidence_distribution?.low || 0,
      },
      assignmentType: {
        auto: agent.auto_vs_manual?.auto || 0,
        manual: agent.auto_vs_manual?.manual || 0,
      },
      performance: {
        successRate: agent.confidence_distribution?.high
          ? (
              (agent.confidence_distribution.high / agent.total_assignments) *
              100
            ).toFixed(1)
          : 0,
        efficiency:
          agent.total_assignments > 0
            ? (
                (agent.active_assignments / agent.total_assignments) *
                100
              ).toFixed(1)
            : 0,
      },
    };
  }

  // Conversation routing recommendations
  async getConversationRecommendations(conversationId) {
    try {
      const routing = await this.getConversationRouting(conversationId);
      return routing.data.recommendations;
    } catch (error) {
      console.error('Failed to get conversation recommendations:', error);
      return {
        recommended_agents: [],
        routing_confidence: 0,
        should_route: false,
        routing_reasons: [],
        fallback_options: {},
      };
    }
  }

  // Routing quality metrics
  async getRoutingQualityMetrics(timeRange = '7d') {
    const analytics = await this.getAnalytics(timeRange);
    const conversations = await this.getConversationsNeedingAttention();

    const data = analytics.data;
    const needsAttention = conversations.data;

    const totalConversations =
      (needsAttention.unassigned?.length || 0) +
      (needsAttention.low_confidence?.length || 0) +
      (needsAttention.long_unresolved?.length || 0);

    const overview = data.routing_overview || {};
    const success = data.success_metrics || {};

    return {
      quality: {
        routingAccuracy: success.resolution_rate || 0,
        averageConfidence: overview.average_confidence || 0,
        autoRoutingSuccess:
          overview.auto_assignments && overview.total_assignments
            ? (
                (overview.auto_assignments / overview.total_assignments) *
                100
              ).toFixed(1)
            : 0,
      },
      attention: {
        total: totalConversations,
        unassigned: needsAttention.unassigned?.length || 0,
        lowConfidence: needsAttention.low_confidence?.length || 0,
        longUnresolved: needsAttention.long_unresolved?.length || 0,
      },
      trends: {
        improving: this.calculateRoutingTrend(data.routing_trends),
        resolutionTime: success.avg_resolution_time || 0,
      },
    };
  }

  // Utility method to calculate trends
  calculateRoutingTrend(trends = []) {
    if (trends.length < 2) return 'stable';

    const recent = trends.slice(-3);
    const older = trends.slice(0, 3);

    const recentAvg =
      recent.reduce((sum, t) => sum + (t.avg_confidence || 0), 0) /
      recent.length;
    const olderAvg =
      older.reduce((sum, t) => sum + (t.avg_confidence || 0), 0) / older.length;

    if (recentAvg > olderAvg + 5) return 'improving';
    if (recentAvg < olderAvg - 5) return 'declining';
    return 'stable';
  }

  // Configuration and settings
  async updateRoutingSettings(settings) {
    // This would be implemented when routing settings are added
    return this.post('settings', settings);
  }

  async getRoutingSettings() {
    // This would be implemented when routing settings are added
    return this.get('settings');
  }
}

export default new HelpforceRoutingAPI();
