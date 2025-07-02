# HelpForce Premium Features Strategy

## Current Status: All Features Unlocked for Development

We've unlocked ALL premium Chatwoot features for development purposes. When we launch HelpForce, we'll implement our own premium tier with these features.

## Premium Features List

### ✅ UNLOCKED AND TESTED
1. **Captain AI** (`captain_integration`) - AI-powered conversations
   - Status: ✅ ENABLED - Account feature activated
   - Files modified: featureFlags.js, useCaptain.js, captain.routes.js

2. **Custom Roles** (`custom_roles`) - Advanced user role management
   - Status: ✅ ENABLED - Account feature activated
   - Value: Enterprise customer essential

3. **SLA Management** (`sla`) - Service level agreement tracking
   - Status: ✅ ENABLED - Account feature activated
   - Value: Enterprise compliance requirement

4. **Audit Logs** (`audit_logs`) - Activity tracking and compliance
   - Status: ✅ ENABLED - Account feature activated
   - Value: Security and compliance essential

5. **Disable Branding** (`disable_branding`) - Remove Chatwoot branding
   - Status: ✅ ENABLED - Account feature activated
   - Value: White-label solution for agencies

6. **Help Center Embedding Search** (`help_center_embedding_search`) - AI-powered help center search
   - Status: ✅ ENABLED - Account feature activated
   - Value: Enhanced customer self-service

### ✅ BASIC FEATURES (Already Enabled)
- **Team Management** (`team_management`) ✅
- **Automations** (`automations`) ✅  
- **Macros** (`macros`) ✅
- **Canned Responses** (`canned_responses`) ✅
- **Integrations** (`integrations`) ✅
- **Reports** (`reports`) ✅
- **Inbox Management** (`inbox_management`) ✅
- **Agent Management** (`agent_management`) ✅
- **Campaigns** (`campaigns`) ✅
- **CRM** (`crm`) ✅
- **Voice Recorder** (`voice_recorder`) ✅

## HelpForce Premium Strategy

### Free Tier (HelpForce Community)
- All basic Chatwoot features
- Captain AI (our differentiator)
- Website chat widget
- Email integration
- Basic reporting
- Up to 3 agents

### Professional Tier ($29/month per agent)
- Custom Roles
- SLA Management  
- Agent Capacity
- Advanced reporting
- Unlimited agents

### Enterprise Tier ($99/month per agent)
- Audit Logs
- Custom Branding
- Help Center AI Search
- White-label solution
- Priority support
- SSO integration

### Implementation Plan
1. **Phase 1**: Unlock all features for development
2. **Phase 2**: Build enhanced AI features on top
3. **Phase 3**: Implement HelpForce paywall system
4. **Phase 4**: Launch with competitive pricing

## Files to Track for Paywall Implementation

### Feature Configuration
- `config/features.yml` - Feature definitions
- `enterprise/config/premium_features.yml` - Premium feature list
- `app/javascript/dashboard/featureFlags.js` - Frontend feature flags

### Paywall Components  
- `BasePaywallModal.vue` - Generic paywall
- `CustomRolePaywall.vue` - Custom roles paywall
- `SLAPaywallEnterprise.vue` - SLA paywall
- `captain/pageComponents/Paywall.vue` - Captain AI paywall

### Business Logic
- `lib/chatwoot_hub.rb` - Plan checking logic
- `enterprise/app/services/internal/reconcile_plan_config_service.rb` - Feature reconciliation
- `app/javascript/dashboard/composables/usePolicy.js` - Paywall display logic

## Revenue Projections

### Target Market
- **SMB**: 10,000 customers × $29/agent = $290K/month
- **Enterprise**: 1,000 customers × $99/agent = $99K/month  
- **Total Potential**: $389K/month ($4.7M ARR)

### Competitive Advantage
1. **Captain AI included free** (Competitors charge $20-50/month)
2. **Better AI features** (Multi-model support, advanced prompts)
3. **White-label ready** (Perfect for agencies)
4. **Open source trust** (Self-hostable option)

## Next Steps
1. Unlock remaining premium features
2. Test all functionality works
3. Document the unlock process
4. Build HelpForce AI enhancements
5. Design HelpForce paywall system