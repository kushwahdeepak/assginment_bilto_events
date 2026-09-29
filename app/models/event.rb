class Event < ApplicationRecord
	validates :external_id, presence: true, uniqueness: true
	validates :title, presence: true
	validates :start_date, presence: true
end
