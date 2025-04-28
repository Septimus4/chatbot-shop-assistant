class User < ApplicationRecord
  # Devise modules (you can add others later like :confirmable, :lockable, etc)
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # Personal information
  validates :first_name, :last_name, presence: true

  # Contact Information
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP}, uniqueness: true

  # Relationships
  has_many :chats, dependent: :destroy
  has_many :messages, through: :chats
  has_many :orders, dependent: :destroy
  has_many :addresses, dependent: :destroy
end
