# Chatwoot References Report - HelpForce Codebase

## Summary
This report documents all remaining references to "Chatwoot" or "chatwoot" in the HelpForce codebase, excluding node_modules, tmp, log, .git, vendor, and spec directories.

## Statistics
- **Ruby files (.rb)**: 173 files containing references
- **JavaScript files (.js)**: 115 files containing references
- **Vue files (.vue)**: 104 files containing references
- **YAML files (.yml/.yaml)**: 20+ files containing references
- **JSON files (.json)**: 50+ files containing references (mostly i18n)
- **Markdown files (.md)**: 12 files containing references
- **Environment files (.env)**: 2 files containing references

## Critical Areas Requiring Changes

### 1. Ruby Files (.rb)

#### Class/Module Names
- `ChatwootHub` class in `/lib/chatwoot_hub.rb` - Should be renamed to `HelpForceHub`
- `ChatwootExceptionTracker` - Referenced in multiple files, needs renaming
- `ChatwootApp` - Referenced in multiple files
- `ChatwootMarkdownRenderer` - Used in article rendering
- `ChatwootCaptcha` - Used in account creation

#### Configuration & Constants
- `CHATWOOT_HUB_URL` environment variable
- `CHATWOOT_INSTALLATION_ONBOARDING` Redis key
- `LATEST_CHATWOOT_VERSION` Redis key
- `CHATWOOT_INSTANCE_ADMIN_EMAIL` configuration
- `CHATWOOT_INBOX_HMAC_KEY` configuration
- `CHATWOOT_SUPPORT_WEBSITE_TOKEN` configuration
- `CHATWOOT_SUPPORT_SCRIPT_URL` configuration
- `CHATWOOT_SUPPORT_IDENTIFIER_HASH` configuration

#### Critical Files
- `/app/models/channel/web_widget.rb` - Line 73: `window.chatwootSDK.run`
- `/app/controllers/installation/onboarding_controller.rb` - Hub registration
- `/app/controllers/public_controller.rb` - Support email reference
- `/lib/chatwoot_hub.rb` - Entire file needs refactoring

### 2. JavaScript/TypeScript Files

#### SDK References
- `window.chatwootSDK` - Widget SDK initialization
- `window.$chatwoot` - Global widget object
- SDK event names containing "CHATWOOT"

#### Configuration
- Feature flags referencing Chatwoot
- API client configurations
- Widget configuration objects

#### Critical Files
- `/app/javascript/widget/helpers/actionCable.js`
- `/app/javascript/sdk/IFrameHelper.js`
- `/app/javascript/dashboard/featureFlags.js`
- `/app/javascript/shared/store/globalConfig.js`

### 3. Vue Components

#### UI References
- "Powered by Chatwoot" text in widget
- Chatwoot branding in various components
- Help text and tooltips mentioning Chatwoot

#### Critical Components
- `/app/javascript/widget/App.vue`
- `/app/javascript/widget/components/ChatFooter.vue`
- `/app/javascript/dashboard/components/layout/sidebarComponents/OptionsMenu.vue`

### 4. Configuration Files

#### YAML Files
- Docker compose files
- Swagger documentation
- Premium installation config
- Feature configuration files

#### JSON Files (i18n)
- All locale files contain "Powered by Chatwoot" translations
- Help text and UI strings referencing Chatwoot
- Error messages mentioning Chatwoot

### 5. Environment Files
- `.env.example` - Multiple references in comments and configuration
- Documentation URLs pointing to chatwoot.com

### 6. Markdown Documentation
- `README.md` - Project description and setup instructions
- `CONTRIBUTING.md` - Contribution guidelines
- `SECURITY.md` - Security policy
- Various guide files referencing Chatwoot

## Recommended Changes by Priority

### High Priority (User-Facing)
1. **Widget Branding**
   - "Powered by Chatwoot" → "Powered by HelpForce"
   - Update all i18n files (50+ locale files)
   
2. **JavaScript SDK**
   - `chatwootSDK` → `helpforceSDK`
   - Update widget initialization code
   
3. **Public URLs & Emails**
   - support@chatwoot.com → support email for HelpForce
   - Documentation URLs

### Medium Priority (Internal)
1. **Class/Module Names**
   - Rename Ruby classes and modules
   - Update all references in codebase
   
2. **Environment Variables**
   - Create mapping for backward compatibility
   - Update documentation
   
3. **Configuration Keys**
   - Update Redis keys
   - Update configuration namespaces

### Low Priority (Comments/Docs)
1. **Code Comments**
   - Update internal documentation
   - Fix references in inline comments
   
2. **Markdown Files**
   - Update project documentation
   - Fix setup guides

## Implementation Strategy

1. **Create Migration Script**
   - Automated search and replace for safe changes
   - Manual review for context-sensitive changes

2. **Backward Compatibility**
   - Keep old environment variable names as fallbacks
   - Deprecation warnings for old configurations

3. **Testing**
   - Comprehensive test suite run after changes
   - Manual testing of critical user flows

4. **Staged Rollout**
   - Phase 1: Internal references (classes, modules)
   - Phase 2: Configuration and environment
   - Phase 3: User-facing strings and UI
   - Phase 4: Documentation and comments

## Files Requiring Manual Review

These files contain complex references that need careful manual review:

1. `/lib/chatwoot_hub.rb` - Core hub communication
2. `/app/models/channel/web_widget.rb` - Widget script generation
3. `/app/javascript/sdk/IFrameHelper.js` - SDK core functionality
4. `/app/javascript/widget/helpers/actionCable.js` - WebSocket connections
5. All environment configuration files

## Next Steps

1. Review this report with the team
2. Prioritize changes based on business requirements
3. Create detailed migration plan
4. Implement changes in phases
5. Thoroughly test each phase
6. Update documentation