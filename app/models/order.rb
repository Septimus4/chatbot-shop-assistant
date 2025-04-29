class Order < ApplicationRecord
  validates :products, presence: true
  belongs_to :user
  belongs_to :address
end
