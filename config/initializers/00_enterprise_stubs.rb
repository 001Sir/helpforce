# frozen_string_literal: true

# Enterprise module method stubs
# Provides backwards compatibility for enterprise module injection methods
# that were disabled when the enterprise system was refactored

module EnterpriseModuleStubs
  def prepend_mod_with(constant_name, namespace: Object, with_descendants: false)
    # No-op: Enterprise module injection has been replaced with simpler system
    # This stub prevents NoMethodError when old enterprise injection calls are made
    Rails.logger.debug { "Enterprise module stub: prepend_mod_with called for #{constant_name}" }
  end

  def extend_mod_with(constant_name, namespace: Object)
    # No-op: Enterprise module injection has been replaced with simpler system
    Rails.logger.debug { "Enterprise module stub: extend_mod_with called for #{constant_name}" }
  end

  def include_mod_with(constant_name, namespace: Object)
    # No-op: Enterprise module injection has been replaced with simpler system
    Rails.logger.debug { "Enterprise module stub: include_mod_with called for #{constant_name}" }
  end

  def prepend_mod(with_descendants: false)
    # No-op: Enterprise module injection has been replaced with simpler system
    Rails.logger.debug { "Enterprise module stub: prepend_mod called for #{name}" }
  end

  def extend_mod
    # No-op: Enterprise module injection has been replaced with simpler system
    Rails.logger.debug { "Enterprise module stub: extend_mod called for #{name}" }
  end

  def include_mod
    # No-op: Enterprise module injection has been replaced with simpler system
    Rails.logger.debug { "Enterprise module stub: include_mod called for #{name}" }
  end
end

# Extend all classes and modules with the stub methods
Module.prepend(EnterpriseModuleStubs)