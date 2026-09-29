require 'rails_helper'

RSpec.describe Event, type: :model do
  subject { Event.new(external_id: "ext_1", title: "Tech Conf", start_date: Time.current) }

  it { is_expected.to validate_presence_of(:external_id) }
  it { is_expected.to validate_presence_of(:title) }
  it { is_expected.to validate_presence_of(:start_date) }
end
