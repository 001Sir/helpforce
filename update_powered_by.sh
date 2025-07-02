#!/bin/bash

echo "Updating 'Powered by Chatwoot' to 'Powered by WorqChat' in all locale files..."

# Update widget locale files
find app/javascript/widget/i18n/locale -name "*.json" -type f -exec sed -i '' 's/"POWERED_BY": "Powered by Chatwoot"/"POWERED_BY": "Powered by WorqChat"/g' {} \;

# Update survey locale files  
find app/javascript/survey/i18n/locale -name "*.json" -type f -exec sed -i '' 's/"POWERED_BY": "Powered by Chatwoot"/"POWERED_BY": "Powered by WorqChat"/g' {} \;

echo "✅ Updated all 'Powered by' references in locale files"

# Count how many files were updated
WIDGET_COUNT=$(grep -l "Powered by WorqChat" app/javascript/widget/i18n/locale/*.json 2>/dev/null | wc -l)
SURVEY_COUNT=$(grep -l "Powered by WorqChat" app/javascript/survey/i18n/locale/*.json 2>/dev/null | wc -l)

echo "📊 Stats:"
echo "- Widget locale files updated: $WIDGET_COUNT"
echo "- Survey locale files updated: $SURVEY_COUNT"
echo "- Total files updated: $((WIDGET_COUNT + SURVEY_COUNT))"