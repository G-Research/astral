ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "minitest/mock"
require "minitest/spec"
require "mocha/minitest"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Helper methods

    def make_signed_jwt(json)
      JWT.encode(json, Config[:jwt_signing_key])
    end

    def jwt_authorized
      @@authorized_token ||= make_signed_jwt(@@authorized_data)
    end

    def jwt_unauthorized
      @@unauthorized_token ||= JWT.encode(@@unauthorized_data, "bad_secret")
    end

    def jwt_read_group
      @@read_group_token ||= make_signed_jwt(@@read_group_data)
    end

    private

    @@authorized_data   = { "sub"=>"john.doe@example.com", "name"=>"John Doe", "iat"=>1516239022,
                            "groups"=>[ "group1", "group2" ], "aud"=>"astral" }
    @@unauthorized_data = { "sub"=>"application_name", "common_name"=>"example.com", "ip_sans"=>"10.0.1.100" }
    @@read_group_data   = { "sub"=>"exene.cervenka@example.com", "name"=>"Exene Cervenka", "iat"=>1516239022,
                            "groups"=>[ "read_group" ], "aud"=>"astral" }
  end
end
