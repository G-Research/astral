class OidcProvider
  attr_reader :client_id
  attr_reader :client_secret
  attr_reader :vault_client

  def configure
    provider = vault_client.logical.read("identity/oidc/provider/astral")
    if provider.nil?
      create_provider_webapp
      create_provider_with_email_scope
      create_entity_for_initial_user
      create_userpass_for_initial_user
      map_userpass_to_entity
    else
      get_client_info
    end
  end


  def get_client_info
    app = vault_client.logical.read(WEBAPP_NAME)
    @client_id = app.data[:client_id]
    @client_secret = app.data[:client_secret]
    [ @client_id, @client_secret ]
  end

  def get_info
    vault_client.logical.read("identity/oidc/provider/astral")
  end

  def self.get_configured_issuer
    Config[:oidc_provider_addr] + Config[:oidc_issuer_path]
  end

  private
  WEBAPP_NAME = "identity/oidc/client/astral"

  def vault_client
    @vault_client ||=
      ::Vault::Client.new(
        address: Config[:oidc_provider_addr],
        token: Config[:vault_token],
        ssl_ca_cert: Config[:oidc_provider_ssl_cert],
        ssl_pem_file: Config[:oidc_provider_ssl_client_cert],
        ssl_key_file: Config[:oidc_provider_ssl_client_key]
      )
  end

  def create_provider_webapp
    vault_client.logical.write(
      WEBAPP_NAME,
      redirect_uris: Config[:oidc_redirect_uris],
      assignments: "allow_all")
    get_client_info
  end

  def create_provider_with_email_scope
    vault_client.logical.write("identity/oidc/scope/email",
                                template: '{"email": {{identity.entity.metadata.email}}}')
    vault_client.logical.write("identity/oidc/provider/astral",
                                issuer: Config[:oidc_provider_addr],
                                allowed_client_ids: @client_id,
                                scopes_supported: "email")
    vault_client.logical.read("identity/oidc/provider/astral")
  end

  def create_entity_for_initial_user
    vault_client.logical.write("identity/entity",
                                policies: "default",
                                name: Config[:initial_user_name],
                                metadata: "email=#{Config[:initial_user_email]}",
                                disabled: false)
  end

  def create_userpass_for_initial_user
    vault_client.logical.delete("/sys/auth/userpass")
    vault_client.logical.write("/sys/auth/userpass", type: "userpass")
    vault_client.logical.write("/auth/userpass/users/#{Config[:initial_user_name]}",
                                password: Config[:initial_user_password])
  end

  def map_userpass_to_entity
    entity = vault_client.logical.read(
      "identity/entity/name/#{Config[:initial_user_name]}")
    entity_id = entity.data[:id]
    auth_list = vault_client.logical.read("/sys/auth")
    accessor = auth_list.data[:"userpass/"][:accessor]
    vault_client.logical.write("identity/entity-alias",
                                name: Config[:initial_user_name],
                                canonical_id: entity_id,
                                mount_accessor: accessor)
  end
end
