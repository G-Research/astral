class OidcProvider
  attr_reader :client_id
  attr_reader :client_secret
  attr_reader :provider

  def configure
    provider = oidc_provider.logical.read("identity/oidc/provider/astral")
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
    app = oidc_provider.logical.read(WEBAPP_NAME)
    @client_id = app.data[:client_id]
    @client_secret = app.data[:client_secret]
    [@client_id, @client_secret]
  end

  def get_info
    oidc_provider.logical.read("identity/oidc/provider/astral")
  end

  private
  WEBAPP_NAME = "identity/oidc/client/astral"

  def oidc_provider
    @provider ||=
      ::Vault::Client.new(
        address: Config[:oidc_provider_addr],
        token: Config[:vault_token]
      )
  end

  def create_provider_webapp
    oidc_provider.logical.write(
      WEBAPP_NAME,
      redirect_uris: Config[:oidc_redirect_uris],
      assignments: "allow_all")
    get_client_info
  end

  def create_provider_with_email_scope
    oidc_provider.logical.write("identity/oidc/scope/email",
                                template: '{"email": {{identity.entity.metadata.email}}}')
    oidc_provider.logical.write("identity/oidc/provider/astral",
                                issuer: "http://oidc_provider:8300",
                                allowed_client_ids: @client_id,
                                scopes_supported: "email")
    oidc_provider.logical.read("identity/oidc/provider/astral")
  end

  def create_entity_for_initial_user
    oidc_provider.logical.write("identity/entity",
                                policies: "default",
                                name: initial_user[:name],
                                metadata: "email=#{initial_user[:email]}",
                                disabled: false)
  end

  def create_userpass_for_initial_user
    oidc_provider.logical.delete("/sys/auth/userpass")
    oidc_provider.logical.write("/sys/auth/userpass", type: "userpass")
    oidc_provider.logical.write("/auth/userpass/users/#{initial_user[:name]}",
                                password: initial_user[:password])
  end

  def map_userpass_to_entity
    entity = oidc_provider.logical.read(
      "identity/entity/name/#{initial_user[:name]}")
    entity_id = entity.data[:id]
    auth_list = oidc_provider.logical.read("/sys/auth")
    accessor = auth_list.data[:"userpass/"][:accessor]
    oidc_provider.logical.write("identity/entity-alias",
                                name: initial_user[:name],
                                canonical_id: entity_id,
                                mount_accessor: accessor)
  end

  def initial_user
    raise "initial user not configured." unless Config[:initial_user]
    Config[:initial_user]
  end

end
