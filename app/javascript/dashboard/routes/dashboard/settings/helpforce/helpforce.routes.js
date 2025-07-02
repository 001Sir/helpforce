import { frontendURL } from 'dashboard/helper/URLHelper';

const SettingsWrapper = () => import('../SettingsWrapper.vue');
const HelpForceIndex = () => import('./Index.vue');
const HelpForceMarketplace = () => import('./Marketplace.vue');
const HelpForceAgents = () => import('./Agents.vue');
const HelpForceRouting = () => import('./Routing.vue');
const HelpForceAnalytics = () => import('./Analytics.vue');

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/settings/helpforce'),
      component: SettingsWrapper,
      children: [
        {
          path: '',
          name: 'helpforce_dashboard',
          component: HelpForceIndex,
          meta: {
            permissions: ['administrator'],
          },
        },
        {
          path: 'marketplace',
          name: 'helpforce_marketplace',
          component: HelpForceMarketplace,
          meta: {
            permissions: ['administrator'],
          },
        },
        {
          path: 'agents',
          name: 'helpforce_agents',
          component: HelpForceAgents,
          meta: {
            permissions: ['administrator'],
          },
        },
        {
          path: 'routing',
          name: 'helpforce_routing',
          component: HelpForceRouting,
          meta: {
            permissions: ['administrator'],
          },
        },
        {
          path: 'analytics',
          name: 'helpforce_analytics',
          component: HelpForceAnalytics,
          meta: {
            permissions: ['administrator'],
          },
        },
      ],
    },
  ],
};
