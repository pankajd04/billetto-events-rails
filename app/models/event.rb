class Event < ApplicationRecord
  has_many :votes, dependent: :destroy
  
  validates :external_id, presence: true, uniqueness: true
  validates :title, presence: true
end