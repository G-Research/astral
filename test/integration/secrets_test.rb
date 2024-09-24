require "test_helper"

class SecretsTest < ActionDispatch::IntegrationTest
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

  test "#show" do
    create_secret
    # view the secret
    get secret_path("top/secret/key"), headers: { "Authorization" => "Bearer #{jwt_authorized}" }
    assert_response :success
    %w[ data metadata lease_id ].each do |key|
      assert_includes response.parsed_body["secret"].keys, key
    end
  end

  test "#delete" do
    create_secret
    # delete the secret
    delete destroy_secret_path("top/secret/key"), headers: { "Authorization" => "Bearer #{jwt_authorized}" }
    assert_response :success
  end

  private

  def create_secret
    # create the secret
    post secrets_path, headers: { "Authorization" => "Bearer #{jwt_authorized}" },
         params: { secret: { path: "top/secret/key", data: { password: "sicr3t" } } }
  end

  def remove_pki_engine
    vault_client.sys.unmount "pki_astral"
  end
end
