class Chat < ApplicationRecord
  # Relationships
  belongs_to :user
  has_many :messages, dependent: :destroy

  # Timestamps for tracking chat sessions
  validates :started_at, presence: true
end
