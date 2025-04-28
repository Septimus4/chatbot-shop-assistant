class Order < ApplicationRecord
  # Order Details
  validates :products, presence: true

  # Relationships
  belongs_to :user
  has_one :address

  # Serializes arrays and hashes for storage in JSON columns
  serialize :products, Array
end
