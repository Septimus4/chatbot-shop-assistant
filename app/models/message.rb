class Message < ApplicationRecord
  # Relationships
  belongs_to :chat
  belongs_to :user, optional: true

  # Message content and metadata
  validates :content, presence: true
  enum :sender_type, { user: "user", ai: "ai" }

  # Timestamps for tracking message order
  default_scope -> { order(created_at: :asc) }
end
