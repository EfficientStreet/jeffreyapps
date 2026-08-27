ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "minitest/mock"
require "webmock/minitest"

# Outbound HTTP (e.g. UrlMetadataFetcher's bookmark title fetches) must be
# stubbed per-test with `stub_request`. Localhost stays open so Capybara's
# system tests can still talk to the local Rails server and webdriver, and so
# the SSR smoke test can reach the Node render server on localhost:13714.
WebMock.disable_net_connect!(allow_localhost: true)

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end
end
