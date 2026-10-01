ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    def sign_in_as(user)
      visit root_path
      page.driver.browser.manage.add_cookie(
        name: "mock_clerk_user_id",
        value: user.clerk_id,
        path: "/"
      )
    end
  end
end