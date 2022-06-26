class User < ActiveRecord::Base
  devise :database_authenticatable, :registerable, :recoverable, :validatable, :rememberable

  validates :name, presence: true

  validates :is_admin, inclusion: {in: [true, false]}, allow_nil: false

  validates :balance, numericality: {only_integer: true}, allow_nil: false

  has_many :games, dependent: :destroy

  def average_prize
    (balance.to_f/games.count).round unless games.count.zero?
  end
end
