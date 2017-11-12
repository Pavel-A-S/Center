# User record
class UserRecord < ActiveRecord::Base
  belongs_to :user

  validates :last_name, presence: true, length: { maximum: 100 }
  validates :first_name, presence: true, length: { maximum: 100 }
  validates :middle_name, presence: true, length: { maximum: 100 }
  validates :document_type, presence: true, length: { maximum: 100 }
  validates :document_number, presence: true, length: { maximum: 100 }
  validates :document_description, presence: true, length: { maximum: 1000 }
  validates :initiator, length: { maximum: 500 }
  validates :description, length: { maximum: 1000 }
end
