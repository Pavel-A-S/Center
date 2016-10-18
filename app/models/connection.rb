class Connection < ActiveRecord::Base
  has_many :ports

  validates :name, presence: true, length: { maximum: 250 }
  validates :login, presence: true
  validates :password, presence: true
  validates :identifier, presence: true, uniqueness: { case_sensitive: false }
  validates :frequency, numericality: { greater_than: 0, less_than: 100000 }
  validates :time_out, numericality: { greater_than: 0, less_than: 100000 }

end
