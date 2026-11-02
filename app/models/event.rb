
class Event < ApplicationRecord
  has_many :votes, dependent: :destroy
  has_one :event_vote_count, dependent: :destroy

  validates :external_id, presence: true, uniqueness: true
  validates :title, presence: true
end
