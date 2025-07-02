# frozen_string_literal: true

# Enterprise Features Concern
# Provides easy access to enterprise features for models and controllers

module EnterpriseFeatures
  extend ActiveSupport::Concern

  included do
    # Add instance methods to models that include this concern
  end

  # Instance methods
  def has_captain_ai?
    WorqChatEnterprise.captain_ai_enabled?
  end

  def has_sla_policies?
    WorqChatEnterprise.sla_policies_enabled?
  end

  def has_custom_roles?
    WorqChatEnterprise.custom_roles_enabled?
  end

  def has_audit_logs?
    WorqChatEnterprise.audit_logs_enabled?
  end

  # Class methods
  class_methods do
    def enterprise_feature?(feature)
      WorqChatEnterprise.feature_enabled?(feature)
    end

    def captain_ai_enabled?
      WorqChatEnterprise.captain_ai_enabled?
    end
  end
end