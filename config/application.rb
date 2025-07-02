# frozen_string_literal: true

require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

## Load the specific APM agent
# We rely on DOTENV to load the environment variables
# We need these environment variables to load the specific APM agent
Dotenv::Rails.load
require 'ddtrace' if ENV.fetch('DD_TRACE_AGENT_URL', false).present?
require 'elastic-apm' if ENV.fetch('ELASTIC_APM_SECRET_TOKEN', false).present?
require 'scout_apm' if ENV.fetch('SCOUT_KEY', false).present?

if ENV.fetch('NEW_RELIC_LICENSE_KEY', false).present?
  require 'newrelic-sidekiq-metrics'
  require 'newrelic_rpm'
end

if ENV.fetch('SENTRY_DSN', false).present?
  require 'sentry-ruby'
  require 'sentry-rails'
  require 'sentry-sidekiq'
end

# heroku autoscaling
if ENV.fetch('JUDOSCALE_URL', false).present?
  require 'judoscale-rails'
  require 'judoscale-sidekiq'
end

# Enable enterprise features with careful error handling
# This must be defined BEFORE Module.prepend is called in initializers
if ENV['ENABLE_ENTERPRISE_SAFELY'] == 'true'
  require_relative '../lib/inject_enterprise_edition'

  class Module
    alias original_prepend_mod_with prepend_mod_with if method_defined?(:prepend_mod_with)

    def prepend_mod_with(constant_name, namespace: Object, with_descendants: false)
      original_prepend_mod_with(constant_name, namespace: namespace, with_descendants: with_descendants)
    rescue NameError => e
      Rails.logger.warn "Enterprise module not found: #{constant_name} - #{e.message}" if Rails.logger
    end

    def extend_mod_with(constant_name, namespace: Object)
      super
    rescue NameError => e
      Rails.logger.warn "Enterprise module extend not found: #{constant_name} - #{e.message}" if Rails.logger
    end

    def include_mod_with(constant_name, namespace: Object)
      super
    rescue NameError => e
      Rails.logger.warn "Enterprise module include not found: #{constant_name} - #{e.message}" if Rails.logger
    end
  end
else
  # Keep enterprise disabled by default until we're sure it works
  class Module
    def prepend_mod_with(_constant_name, namespace: Object, with_descendants: false)
      Rails.logger.info 'Enterprise features disabled' if Rails.logger
      return
    end

    def extend_mod_with(_constant_name, namespace: Object)
      return
    end

    def include_mod_with(_constant_name, namespace: Object)
      return
    end
  end
end

module WorqChat
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0

    config.eager_load_paths << Rails.root.join('lib')
    # Load enterprise paths when enabled
    if ENV['ENABLE_ENTERPRISE_SAFELY'] == 'true' || (ENV['DISABLE_ENTERPRISE'] != 'true' && !Rails.env.production?)
      config.eager_load_paths << Rails.root.join('enterprise/lib')
      config.eager_load_paths << Rails.root.join('enterprise/listeners')
      # rubocop:disable Rails/FilePath
      config.eager_load_paths += Dir["#{Rails.root}/enterprise/app/**"]
      # rubocop:enable Rails/FilePath
      # Add enterprise views to the view paths
      config.paths['app/views'].unshift('enterprise/app/views')
    end

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.
    config.generators.javascripts = false
    config.generators.stylesheets = false

    # Custom chatwoot configurations
    config.x = config_for(:app).with_indifferent_access

    # https://stackoverflow.com/questions/72970170/upgrading-to-rails-6-1-6-1-causes-psychdisallowedclass-tried-to-load-unspecif
    # https://discuss.rubyonrails.org/t/cve-2022-32224-possible-rce-escalation-bug-with-serialized-columns-in-active-record/81017
    # FIX ME : fixes breakage of installation config. we need to migrate.
    config.active_record.yaml_column_permitted_classes = [ActiveSupport::HashWithIndifferentAccess]
  end

  def self.config
    @config ||= Rails.configuration.x
  end

  def self.redis_ssl_verify_mode
    # Introduced this method to fix the issue in heroku where redis connections fail for redis 6
    # ref: https://github.com/chatwoot/chatwoot/issues/2420
    #
    # unless the redis verify mode is explicitly specified as none, we will fall back to the default 'verify peer'
    # ref: https://www.rubydoc.info/stdlib/openssl/OpenSSL/SSL/SSLContext#DEFAULT_PARAMS-constant
    ENV['REDIS_OPENSSL_VERIFY_MODE'] == 'none' ? OpenSSL::SSL::VERIFY_NONE : OpenSSL::SSL::VERIFY_PEER
  end
end
