# frozen_string_literal: true

# Devise configures Warden only once (@@warden_configured). When a second
# authenticatable model (Fsp) is introduced while the app is already running,
# or after a partial reload, the :fsp scope can end up with no strategies.
# Login then fails immediately with "Invalid email or password" and zero DB queries.
#
# Re-register Warden scopes whenever the FSP strategies are missing.
Rails.application.config.to_prepare do
  next unless defined?(Devise)
  next unless Devise.mappings[:fsp]
  next unless Devise.warden_config

  fsp_strategies = Array(Devise.warden_config.default_strategies(scope: :fsp))
  next if fsp_strategies.any?

  if Devise.class_variable_defined?(:@@warden_configured)
    Devise.class_variable_set(:@@warden_configured, nil)
  end
  Devise.configure_warden!
end
