
class Vote < ApplicationRecord
  belongs_to :event

  DIRECTIONS = %w[upvote downvote].freeze

  validates :clerk_user_id, presence: true
  validates :direction, inclusion: { in: DIRECTIONS }
  validates :clerk_user_id,
            uniqueness: { scope: :event_id }
end
