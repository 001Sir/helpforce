# frozen_string_literal: true

require 'pathname'

module WorqChatApp
  def self.root
    Pathname.new(File.expand_path('..', __dir__))
  end

  def self.max_limit
    100_000
  end

  def self.enterprise?
    return if ActiveModel::Type::Boolean.new.cast(ENV.fetch('DISABLE_ENTERPRISE', false))

    @enterprise ||= root.join('enterprise').exist?
  end

  def self.worqchat_cloud?
    enterprise? && GlobalConfig.get_value('DEPLOYMENT_ENV') == 'cloud'
  end

  def self.custom?
    @custom ||= root.join('custom').exist?
  end

  def self.help_center_root
    ENV.fetch('HELPCENTER_URL', nil) || ENV.fetch('FRONTEND_URL', nil)
  end

  def self.extensions
    if custom?
      %w[enterprise custom]
    elsif enterprise?
      %w[enterprise]
    else
      %w[]
    end
  end
end
