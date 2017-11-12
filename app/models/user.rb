# User
class User < ActiveRecord::Base
  enum record_type: %i[income expenditure exchange]

  enum role: %i[security engineer administrator]

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :recoverable, :rememberable, :trackable,
         :validatable # :registerable
end
