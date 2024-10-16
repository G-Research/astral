require "rake"
require_relative "../../app/lib/utils/oidc_provider"
data = YAML.load(File.read("config/astral.yml"))
initial_user = data["test"]["initial_user"].stringify_keys

# Rake tasks for oidc provider
namespace :oidc_provider do
  desc "Configure the provider"
  task :configure do
    OidcProvider.new.configure ENV["VAULT_TOKEN"], initial_user
  end
end
