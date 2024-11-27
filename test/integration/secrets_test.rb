require "test_helper"

class SecretsTest < ActionDispatch::IntegrationTest
  setup do
    jwt_json = unique_jwt
    @jwt_groups = jwt_json["groups"]
    @jwt_authorized = make_signed_jwt(jwt_json)
    jwt_read_group_json = unique_jwt.tap { |h| h["groups"] = @jwt_groups }
    @jwt_read_group = make_signed_jwt(jwt_read_group_json)
  end

  test "#create unauthorized" do
    post secrets_path
    assert_response :unauthorized
  end

  test "#create with faulty token (encoded with different signing key)" do
    post secrets_path, headers: { "Authorization" => "Bearer #{jwt_unauthorized}" }
    assert_response :unauthorized
  end

  test "#create or update a secret" do
    create_secret
    assert_response :success
    %w[ data metadata lease_id ].each do |key|
      assert_includes response.parsed_body["secret"].keys, key
    end
  end

  test "#update an existing secret with same user is authorized" do
    existing_path = create_secret
    assert_response :success
    create_secret(@jwt_authorized, existing_path)
    assert_response :success
  end

  test "#update an existing secret with a different user is unauthorized" do
    existing_path = create_secret
    assert_response :success
    create_secret(jwt_read_group, existing_path)
    assert_response :unauthorized
  end

  test "#show" do
    path = create_secret
    # view the secret
    get secret_path(path), headers: { "Authorization" => "Bearer #{@jwt_authorized}" }
    assert_response :success
    %w[ data metadata lease_id ].each do |key|
      assert_includes response.parsed_body["secret"].keys, key
    end
  end

  test "#show with read_group is authorized" do
    path = create_secret
    # view the secret
    get secret_path(path), headers: { "Authorization" => "Bearer #{@jwt_read_group}" }
    assert_response :success
    %w[ data metadata lease_id ].each do |key|
      assert_includes response.parsed_body["secret"].keys, key
    end
  end

  test "#delete" do
    path = create_secret
    # delete the secret
    delete destroy_secret_path(path), headers: { "Authorization" => "Bearer #{@jwt_authorized}" }
    assert_response :success
  end

  test "#delete with a read-authorized user is unauthorized" do
    path = create_secret
    # delete the secret
    delete destroy_secret_path(path), headers: { "Authorization" => "Bearer #{@jwt_read_group}" }
    assert_response :unauthorized
  end

  private

  def create_secret(jwt = @jwt_authorized, path = "top/secret/#{SecureRandom.hex}", groups = @jwt_groups)
    # create the secret
    post secrets_path, headers: { "Authorization" => "Bearer #{jwt}" },
         params: { secret: { path: path, data: { password: "sicr3t" }, groups: groups.join(",") } }
    path
  end

  def unique_jwt
    { "sub"=>SecureRandom.hex, "name"=>"John Doe", "iat"=>1516239022,
      "groups"=>[ SecureRandom.hex ], "aud"=>"astral" }
  end
end
