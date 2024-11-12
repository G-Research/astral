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
    def jwt_authorized
      "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJqb2huLmRvZUBleGFtcGxlLmNvbSIsIm5hbWUiOiJKb2huIERvZSIsImlhdCI6MTUxNjIzOTAyMiwiZ3JvdXBzIjpbImdyb3VwMSIsImdyb3VwMiJdLCJhdWQiOiJhc3RyYWwifQ.tfRLXmE_eq-piP88_clwPWrYfMAQbCJAeZQI6OFxZSI"
    end

    def jwt_unauthorized
      "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJhcHBsaWNhdGlvbl9uYW1lIiwiY29tbW9uX25hbWUiOiJleGFtcGxlLmNvbSIsImlwX3NhbnMiOiIxMC4wLjEuMTAwIn0.gEUyaZcARiBQNq2RUwZU0MdFXqthyo_oSQ8DAgKvxCs"
    end
  end
end
