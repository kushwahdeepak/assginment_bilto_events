require "application_system_test_case"

class VotingTest < ApplicationSystemTestCase
  setup do
    @event = Event.new(
      title: "Bilto Event",
      description: "Testing voting system",
      start_date: 1.day.from_now
    )
    @event.external_event = false if @event.respond_to?(:external_event=)
    @event.save!(validate: false)

    if defined?(EventStat)
      EventStat.find_or_create_by!(event_id: @event.id) do |s|
        s.upvotes_count = 0
        s.downvotes_count = 0
      end
    end
  end

  test "user signs in, votes on event, checks vote count change, and signs out" do
    visit root_path

    page.driver.browser.manage.add_cookie(
      name: "mock_clerk_user_id",
      value: "user_mock123",
      path: "/"
    )

    visit event_path(@event)

    assert_text "Sign Out"
    assert_selector "#vote-count", text: "0"

    click_button "Upvote"

    begin
      assert_selector "#vote-count", text: "1", wait: 3
    rescue Capybara::ElementNotFound
      visit event_path(@event)
      assert_selector "#vote-count", text: "1", wait: 5
    end

    click_on "Sign Out"
    assert_text "Sign In"
  end
end