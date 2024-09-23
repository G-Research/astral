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
    create_secret("top/secret/key1")
    assert_response :success
    %w[ data metadata lease_id ].each do |key|
      assert_includes response.parsed_body["secret"].keys, key
    end
  end

  test "#show" do
    create_secret("top/secret/key2")
    # pause
    sleep(1)
    # view the secret
    get secret_path("top/secret/key2"), headers: { "Authorization" => "Bearer #{jwt_authorized}" }
    assert_response :success
    %w[ data metadata lease_id ].each do |key|
      assert_includes response.parsed_body["secret"].keys, key
    end
  end

  test "#delete" do
    create_secret("top/secret/key3")
    # pause
    sleep(1)
    # delete the secret
    delete destroy_secret_path("top/secret/key3"), headers: { "Authorization" => "Bearer #{jwt_authorized}" }
    assert_response :success
  end

  private

  def create_secret(path)
    # create the secret
    post secrets_path, headers: { "Authorization" => "Bearer #{jwt_authorized}" },
         params: { secret: { path: path, data: { password: "sicr3t" } } }
  end
end
