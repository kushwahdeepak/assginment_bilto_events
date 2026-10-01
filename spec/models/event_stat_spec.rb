require 'rails_helper'

RSpec.describe EventStat, type: :model do
  subject { described_class.new(event_id: "indore_event_1") }

  it { is_expected.to validate_presence_of(:event_id) }
  it { is_expected.to validate_uniqueness_of(:event_id) }
end
