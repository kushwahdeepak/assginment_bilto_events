FactoryBot.define do
  factory :event do
    sequence(:external_id) { |n| "billetto_indore_#{n}" }
    title { "Indore Heritage Food Festival" }
    description { "Local food, music, and culture near Rajwada Palace in Indore, Madhya Pradesh." }
    start_date { Time.zone.parse("2026-10-10 19:00 +05:30") }
    image_url { "https://example.test/indore-heritage-food-festival.jpg" }
  end
end
