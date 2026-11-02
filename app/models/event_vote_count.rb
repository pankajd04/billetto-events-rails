
class EventVoteCount < ApplicationRecord
  belongs_to :event

  validates :upvotes_count,
            numericality: {
              only_integer: true,
              greater_than_or_equal_to: 0
            }

  validates :downvotes_count,
            numericality: {
              only_integer: true,
              greater_than_or_equal_to: 0
            }
end
