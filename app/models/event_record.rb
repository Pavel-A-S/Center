# Event record
class EventRecord < ActiveRecord::Base
  belongs_to :user

  validates :description, presence: true, length: { maximum: 1000 }
end
