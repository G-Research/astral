require "rake"
require_relative "../../app/lib/utils/oidc_provider"
require_relative "../../app/lib/config"

# Rake tasks for oidc provider
namespace :oidc_provider do
  desc "Configure the provider"
  task :configure do
    OidcProvider.new.configure
  end
end
