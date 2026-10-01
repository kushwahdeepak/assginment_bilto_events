require "application_system_test_case"

class EventsTest < ApplicationSystemTestCase
  test "visitors can browse event details and see vote totals" do
    event = Event.create!(
      external_id: "billetto_indore_browser_test",
      title: "Indore Heritage Food Festival",
      description: "Food, music, and culture near Rajwada Palace in Indore, Madhya Pradesh.",
      start_date: Time.zone.parse("2026-10-10 19:00 +05:30"),
      image_url: "https://example.test/indore-heritage-food-festival.jpg"
    )
    EventStat.create!(event_id: event.id.to_s, upvotes_count: 3, downvotes_count: 1)

    visit root_path

    assert_text "Indore Heritage Food Festival"
    assert_text "Rajwada Palace in Indore, Madhya Pradesh"
    assert_text "3"
    assert_text "1"
    assert_selector "button[data-vote-type='upvote'][disabled]"
  end
end
