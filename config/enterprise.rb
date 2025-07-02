# frozen_string_literal: true

# WorqChat Custom Enterprise System
# Simple, clean enterprise configuration without complex injection

module WorqChatEnterprise
  def self.enabled?
    ENV.fetch('WORQCHAT_ENTERPRISE', 'true') == 'true'
  end

  def self.features
    return [] unless enabled?

    %w[captain_ai sla_policies custom_roles audit_logs]
  end

  def self.feature_enabled?(feature)
    features.include?(feature.to_s)
  end

  # Captain AI specific configuration
  def self.captain_ai_enabled?
    feature_enabled?('captain_ai')
  end

  # SLA Policies
  def self.sla_policies_enabled?
    feature_enabled?('sla_policies')
  end

  # Custom Roles
  def self.custom_roles_enabled?
    feature_enabled?('custom_roles')
  end

  # Audit Logs
  def self.audit_logs_enabled?
    feature_enabled?('audit_logs')
  end
end

# Enterprise configuration loaded automatically when this file is required