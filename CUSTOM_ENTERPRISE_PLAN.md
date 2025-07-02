# Custom Enterprise System Plan

## Overview
Replace the problematic enterprise injection system with a clean, simple implementation focused on our actual needs.

## Phase 1: Core Foundation (Priority: HIGH)

### 1. Simple Enterprise Configuration
```ruby
# config/enterprise.rb
module WorqChatEnterprise
  def self.enabled?
    ENV.fetch('WORQCHAT_ENTERPRISE', 'true') == 'true'
  end
  
  def self.features
    return [] unless enabled?
    %w[captain_ai sla_policies custom_roles audit_logs]
  end
end
```

### 2. Captain AI System (We already have this working!)
**Status: ✅ 80% Complete - Just need to migrate**
- ✅ Assistant management API
- ✅ Authentication working
- ⚠️ Document creation (needs fix)
- ⚠️ Copilot threads (routing issue)

**Migration Plan:**
1. Move existing Captain controllers to `app/controllers/api/v1/captain/`
2. Remove enterprise route dependencies
3. Fix document creation locale issue
4. Test all endpoints

### 3. Simple Feature Flags
```ruby
# app/models/concerns/enterprise_features.rb
module EnterpriseFeatures
  extend ActiveSupport::Concern
  
  def has_captain_ai?
    WorqChatEnterprise.features.include?('captain_ai')
  end
  
  def has_sla_policies?
    WorqChatEnterprise.features.include?('sla_policies')
  end
end
```

## Phase 2: Additional Features (Priority: MEDIUM)

### 1. SLA Policies (If needed)
- Simple time tracking for first response
- Basic SLA status (met/missed)
- Reporting dashboard

### 2. Custom Roles (If needed)
- Basic role-based permissions
- Admin interface for role management

### 3. Audit Logs (If needed)
- Simple activity logging
- User action tracking

## Phase 3: Polish (Priority: LOW)

### 1. Admin Interface
- Enterprise feature toggles
- Configuration management

### 2. API Documentation
- Swagger/OpenAPI docs
- Integration examples

## Implementation Steps

### Step 1: Remove Current Enterprise System
1. ❌ Delete enterprise injection initializer
2. ❌ Remove problematic enterprise routes
3. ❌ Clean up module injection code

### Step 2: Create Clean Captain API
1. ✅ Move Captain controllers to main app
2. ✅ Add routes directly to main routes.rb
3. ✅ Fix document creation
4. ✅ Test all endpoints

### Step 3: Simple Enterprise Config
1. ✅ Add basic enterprise module
2. ✅ Environment-based feature flags
3. ✅ Account-level feature checks

### Step 4: Deploy and Test
1. ✅ Deploy to Heroku (should work now!)
2. ✅ Test Captain API in production
3. ✅ Verify no more crashes

## File Structure (Clean and Simple)

```
app/
├── controllers/
│   └── api/
│       └── v1/
│           └── captain/           # Our Captain API
│               ├── assistants_controller.rb
│               ├── documents_controller.rb
│               └── copilot_threads_controller.rb
├── models/
│   └── captain/                   # Captain models
│       ├── assistant.rb
│       └── document.rb
├── services/
│   └── captain/                   # AI services
│       ├── assistant_service.rb
│       └── llm_service.rb
config/
├── enterprise.rb                  # Simple config
└── routes.rb                      # Clean routes
```

## Benefits of This Approach

1. **No More Crashes**: Simple, predictable code
2. **Easy Deployment**: Works on Heroku without issues
3. **Maintainable**: Clean code we fully understand
4. **Focused**: Only features we actually need
5. **Testable**: Easy to write and run tests
6. **Scalable**: Can add features incrementally

## Timeline

- **Day 1**: Remove old enterprise system, migrate Captain API
- **Day 2**: Fix remaining issues, test locally
- **Day 3**: Deploy to Heroku, test production
- **Week 2**: Add additional features as needed

## Decision: Let's Do It! 🚀

This approach will solve our deployment issues and give us a much cleaner, more maintainable codebase. We'll have full control over the enterprise features and can focus on what actually matters for our users.