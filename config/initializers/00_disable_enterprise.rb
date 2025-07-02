# Temporary fix for Heroku deployment
# Disable enterprise module loading if DISABLE_ENTERPRISE is set
if ENV['DISABLE_ENTERPRISE'] == 'true' || ENV['RAILS_ENV'] == 'production'
  puts 'Enterprise features disabled'

  # Override the module loading methods to be no-ops
  module InjectEnterpriseEditionModule
    def prepend_mod_with(constant_name, namespace: Object, with_descendants: false)
      # Skip enterprise modules
      return if constant_name.to_s.include?('::')

      super
    end

    def include_mod_with(constant_name, namespace: Object)
      # Skip enterprise modules
      return if constant_name.to_s.include?('::')

      super
    end
  end
end