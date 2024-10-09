require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module AstralRails
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.2

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Only loads a smaller set of middleware suitable for API only apps.
    # Middleware like session, flash, cookies can be added back manually.
    # Skip views, helpers and assets when generating a new resource.
    config.api_only = true

    # the secret_key_base isn't used, but Rails requires it
    config.secret_key_base = "secret_key_base_not_used!"

    # Application configs from config/astral.yml
    config.astral = config_for :astral

    config.after_initialize do
      # bootstrap with provided token, then rotate
      Clients::Vault.token = Config[:vault_token]
      Clients::Vault.configure_kv
      Clients::Vault.configure_pki
      issuer = "#{config.astral.oidc_provider[:addr]}/v1/#{config.astral.oidc_provider[:name]}"
      client_id = config.astral.oidc_provider[:client_id]
      client_secret = config.astral.oidc_provider[:client_secret]
      if config.astral.configure_oidc_provider?
        Clients::Vault.configure_oidc_provider
        client_id = ::Clients::Vault::Oidc.client_id
        client_secret = ::Clients::Vault::Oidc.client_secret
      end
      Clients::Vault.configure_oidc_client(issuer, client_id, client_secret)
      Clients::Vault.rotate_token
    end
  end
end
