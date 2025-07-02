# HelpForce Rebranding Guide: From Chatwoot to HelpForce

## Overview
This guide covers how to rebrand Chatwoot into HelpForce, transforming it from an open-source project into your own SaaS product.

## 1. Visual Rebranding

### Logo Changes
```bash
# Replace Chatwoot logos with HelpForce logos
app/assets/images/
├── logo.svg                    # Main logo
├── logo-dark.svg              # Dark mode logo
├── favicon.ico                # Browser favicon
├── apple-touch-icon.png       # Mobile icons
└── logo-thumbnail.png         # Small logo variant

public/
├── favicon.ico
└── apple-touch-icon.png
```

**Create new logos:**
```bash
# Use a tool like Canva or hire a designer
# Recommended: Modern, tech-focused design
# Colors: Blue (#1E40AF) and Green (#10B981) gradient
# Font: Inter or Poppins for modern feel
```

### Brand Colors
```scss
// app/javascript/dashboard/assets/scss/variables.scss
$color-woot: #1E40AF;  // Changed from Chatwoot blue
$color-primary: #1E40AF;
$color-secondary: #10B981;
$color-accent: #F59E0B;

// app/javascript/widget/assets/scss/variables.scss
$color-primary: #1E40AF;
$color-primary-dark: #1E3A8A;
```

### Application Name
```ruby
# config/application.rb
module Helpforce  # Changed from Chatwoot
  class Application < Rails::Application
    config.app_name = 'HelpForce'
  end
end

# config/installation_config.yml
name: 'HelpForce'
logo: 'https://helpforce.app/logo.png'
brand_url: 'https://helpforce.app'
```

## 2. Text & Copy Rebranding

### Frontend String Replacements
```bash
# Find all instances of Chatwoot in frontend
grep -r "Chatwoot" app/javascript/

# Key files to update:
app/javascript/dashboard/i18n/locale/en/
├── generalSettings.json
├── login.json  
├── signup.json
└── settings.json
```

**Example replacements:**
```json
// app/javascript/dashboard/i18n/locale/en/generalSettings.json
{
  "GENERAL_SETTINGS": {
    "TITLE": "HelpForce Settings",
    "SUBMIT": "Update HelpForce Settings",
    "DESCRIPTION": "Configure your HelpForce instance"
  }
}
```

### Backend String Replacements
```yaml
# config/locales/en.yml
en:
  brand_name: 'HelpForce'
  tagline: 'AI-Powered Customer Support Platform'
  
# Update email templates
app/views/mailers/
├── confirmation_instructions.html.erb
├── password_reset.html.erb
└── agent_notifications/
```

### Database Seeds
```ruby
# db/seeds.rb
# Update default account name
account = Account.create!(
  name: 'HelpForce'
)

# Update Super Admin
SuperAdmin.create!(
  email: 'admin@helpforce.app',
  password: 'SecurePassword123!'
)
```

## 3. Email Rebranding

### Email Templates
```erb
<!-- app/views/layouts/mailer.html.erb -->
<div class="header">
  <img src="https://helpforce.app/logo.png" alt="HelpForce" />
  <h1>HelpForce</h1>
  <p>AI-Powered Customer Support</p>
</div>

<!-- Update all email templates -->
<!-- Replace "Chatwoot" with "HelpForce" -->
<!-- Update support email to support@helpforce.app -->
```

### Email Configuration
```ruby
# config/environments/production.rb
config.action_mailer.default_options = {
  from: 'HelpForce Support <support@helpforce.app>'
}

# app/mailers/application_mailer.rb
class ApplicationMailer < ActionMailer::Base
  default from: 'HelpForce <noreply@helpforce.app>'
  layout 'mailer'
end
```

## 4. URL & Domain Changes

### Environment Variables
```bash
# .env.production
FRONTEND_URL=https://app.helpforce.app
INSTALLATION_NAME=HelpForce
SUPPORT_EMAIL=support@helpforce.app
```

### Widget Script
```javascript
// public/embed.js
window.helpforceSettings = {  // Changed from chatwootSettings
  // ... settings
}

(function(d,t) {
  var BASE_URL="https://app.helpforce.app";
  var g=d.createElement(t),s=d.getElementsByTagName(t)[0];
  g.src=BASE_URL+"/packs/js/sdk.js";
  g.defer = true;
  g.async = true;
  s.parentNode.insertBefore(g,s);
  g.onload=function(){
    window.helpforceSDK.run({  // Changed from chatwootSDK
      websiteToken: WEBSITE_TOKEN,
      baseUrl: BASE_URL
    })
  }
})(document,"script");
```

## 5. Legal & Compliance

### Terms of Service
```markdown
# Create app/views/pages/terms.html.erb
# HelpForce Terms of Service

Last updated: [Date]

1. Acceptance of Terms
By accessing HelpForce, you agree to these terms...

2. Description of Service
HelpForce is an AI-powered customer support platform...
```

### Privacy Policy
```markdown
# Create app/views/pages/privacy.html.erb
# HelpForce Privacy Policy

HelpForce ("we", "our", "us") is committed to protecting your privacy...
```

### License Compliance
```markdown
# IMPORTANT: Chatwoot MIT License Requirements

1. Include original MIT license
2. Add attribution in footer
3. Keep copyright notices

# app/views/layouts/_footer.html.erb
<footer>
  <p>Powered by HelpForce</p>
  <p class="small">
    Built on <a href="https://github.com/chatwoot/chatwoot">Chatwoot</a> 
    open-source platform (MIT License)
  </p>
</footer>
```

## 6. Marketing Website

### Landing Page Structure
```
helpforce-website/
├── index.html          # Main landing page
├── pricing.html        # Pricing tiers
├── features.html       # Feature showcase
├── docs/              # Documentation
├── blog/              # Content marketing
└── assets/
    ├── css/
    ├── js/
    └── images/
```

### Landing Page Content
```html
<!DOCTYPE html>
<html>
<head>
  <title>HelpForce - AI-Powered Customer Support Platform</title>
  <meta name="description" content="Transform your customer support with AI agents, smart routing, and multi-model intelligence.">
</head>
<body>
  <!-- Hero Section -->
  <section class="hero">
    <h1>Customer Support, Supercharged with AI</h1>
    <p>Reduce response times by 80% with intelligent routing and AI agents</p>
    <a href="/signup" class="cta-button">Start Free Trial</a>
  </section>

  <!-- Features -->
  <section class="features">
    <div class="feature">
      <h3>🤖 AI Agent Marketplace</h3>
      <p>Choose from 6 specialized AI agents or build your own</p>
    </div>
    <div class="feature">
      <h3>🎯 Smart Routing</h3>
      <p>ML-powered conversation routing to the right agent</p>
    </div>
    <div class="feature">
      <h3>🌐 Multi-Model AI</h3>
      <p>Support for OpenAI, Claude, and Gemini</p>
    </div>
  </section>
</body>
</html>
```

## 7. Social Media & SEO

### Meta Tags
```erb
<!-- app/views/layouts/application.html.erb -->
<meta property="og:title" content="HelpForce - AI Customer Support">
<meta property="og:description" content="Transform your customer support with AI">
<meta property="og:image" content="https://helpforce.app/og-image.png">
<meta name="twitter:card" content="summary_large_image">
<meta name="twitter:site" content="@helpforceapp">
```

### Social Profiles
- Twitter: @helpforceapp
- LinkedIn: /company/helpforce
- GitHub: /helpforce (private repo)
- ProductHunt: @helpforce

## 8. Mobile App Rebranding (if using)

### iOS
```swift
// Info.plist
CFBundleDisplayName = "HelpForce"
CFBundleName = "HelpForce"
```

### Android
```xml
<!-- app/src/main/res/values/strings.xml -->
<string name="app_name">HelpForce</string>
```

## 9. Admin Panel Customization

### Super Admin Branding
```erb
<!-- app/views/super_admin/app_configs/index.html.erb -->
<h1>HelpForce Configuration</h1>

<!-- Update all super_admin views -->
```

### Dashboard Customization
```vue
// app/javascript/dashboard/components/layout/Sidebar.vue
<template>
  <div class="sidebar-brand">
    <img src="/helpforce-logo.svg" alt="HelpForce" />
    <span>HelpForce</span>
  </div>
</template>
```

## 10. Deployment Rebranding

### Docker
```dockerfile
# docker/Dockerfile
LABEL maintainer="HelpForce Team <team@helpforce.app>"
LABEL description="HelpForce - AI-Powered Customer Support"
```

### Kubernetes
```yaml
# k8s/deployment.yaml
metadata:
  name: helpforce
  labels:
    app: helpforce
```

## Quick Rebranding Script

```bash
#!/bin/bash
# rebrand.sh - Quick rebranding script

echo "🎨 Starting HelpForce rebranding..."

# Backup original files
cp -r . ../chatwoot-backup

# Replace strings in Ruby files
find . -name "*.rb" -type f -exec sed -i '' 's/Chatwoot/HelpForce/g' {} +
find . -name "*.erb" -type f -exec sed -i '' 's/Chatwoot/HelpForce/g' {} +

# Replace in JavaScript files
find ./app/javascript -name "*.js" -type f -exec sed -i '' 's/Chatwoot/HelpForce/g' {} +
find ./app/javascript -name "*.vue" -type f -exec sed -i '' 's/Chatwoot/HelpForce/g' {} +

# Replace in JSON files
find . -name "*.json" -type f -exec sed -i '' 's/chatwoot/helpforce/g' {} +

# Update configuration files
sed -i '' 's/Chatwoot/HelpForce/g' config/application.rb
sed -i '' 's/chatwoot/helpforce/g' package.json

echo "✅ Basic rebranding complete!"
echo "⚠️  Manual steps required:"
echo "  1. Replace logo files"
echo "  2. Update color scheme"
echo "  3. Review and test all changes"
echo "  4. Update legal documents"
```

## Testing Rebrand

```bash
# Start application
foreman start -f Procfile.dev

# Check for remaining instances
grep -r "Chatwoot" . --exclude-dir={node_modules,tmp,log,.git} | grep -v Binary

# Visual inspection checklist:
# [ ] Logo appears correctly
# [ ] Brand colors applied
# [ ] Email templates updated
# [ ] Login/Signup pages branded
# [ ] Dashboard shows HelpForce
# [ ] Widget shows HelpForce branding
```

## Important Notes

1. **Keep Attribution**: The MIT license requires attribution. Include "Powered by Chatwoot" in footer.

2. **Update Dependencies**: 
   ```json
   // package.json
   {
     "name": "@helpforce/app",
     "description": "HelpForce - AI-Powered Customer Support"
   }
   ```

3. **SEO Considerations**:
   - Set up redirects from old Chatwoot URLs
   - Update sitemap.xml
   - Submit to search engines

4. **Legal Review**:
   - Have a lawyer review the rebranding
   - Ensure MIT license compliance
   - Trademark search for "HelpForce"

## Monetization After Rebranding

1. **Remove Open Source References**:
   - Remove "Deploy to Heroku" buttons
   - Remove self-hosting documentation
   - Make GitHub repo private

2. **Add Payment Integration**:
   - Stripe for subscriptions
   - Usage tracking for AI operations
   - Billing dashboard

3. **Marketing Site**:
   - Professional landing page
   - Clear pricing tiers
   - Customer testimonials
   - ROI calculator

This rebranding transforms Chatwoot from an open-source project into a professional SaaS product while maintaining legal compliance with the MIT license!