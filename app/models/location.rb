class Location < ActiveRecord::Base
  has_many :ports

  validates :name, presence: true, length: { maximum: 250 }

end
