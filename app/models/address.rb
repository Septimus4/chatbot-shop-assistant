class Address < ActiveRecord::Base
  validates :phone_number, presence: true

  # Shipping Address
  validates :address, presence: true
  validates :postcode, presence: true
  validates :city, presence: true
  validates :country, presence: true
end
