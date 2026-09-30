require 'rails_helper'

RSpec.describe Event, type: :model do
  subject do
    Event.new(
      external_id: "billetto_indore_food_festival",
      title: "Indore Heritage Food Festival",
      start_date: Time.zone.parse("2026-10-10 19:00 +05:30")
    )
  end

  it { is_expected.to validate_presence_of(:external_id) }
  it { is_expected.to validate_presence_of(:title) }
  it { is_expected.to validate_presence_of(:start_date) }
end
