require 'net/http'
require 'uri'
require 'json'

class FetchProductsJob < ApplicationJob
  queue_as :default

  def perform
    url = 'https://dummyjson.com/products'

    begin
      uri = URI.parse(url)
      response = Net::HTTP.get_response(uri)

      unless response.is_a?(Net::HTTPSuccess)
        Rails.logger.error("Failed to fetch products: HTTP #{response.code}")
        return
      end

      data = JSON.parse(response.body)

      return unless data.is_a?(Hash) && data.key?('products')

      total_products = 0

      data['products'].each do |product_hash|
        product = Product.find_or_initialize_by(id: product_hash['id'])
        if product.new_record?
          Rails.logger.info "New product detected. It will be created."
        else
          Rails.logger.info "Existing product detected. It will be updated."
        end

        reviews_array = (product_hash['reviews'] || []).map do |review|
          {
            rating: review['rating'],
            comment: review['comment'],
            date: review['date'],
            reviewer_name: review['reviewerName'],
            reviewer_email: review['reviewerEmail']
          }
        end

        product.attributes = {
          title: product_hash['title'],
          description: product_hash['description'],
          category: product_hash['category'],
          price: product_hash['price'].to_f,
          rating: product_hash['rating'],
          stock: product_hash['stock'],
          brand: product_hash['brand'],
          sku: product_hash['sku'],
          weight: product_hash['weight'],
          tags: product_hash['tags'] || [],
          dimensions: {
            width: product_hash.dig('dimensions', 'width'),
            height: product_hash.dig('dimensions', 'height'),
            depth: product_hash.dig('dimensions', 'depth')
          },
          warranty_information: product_hash['warrantyInformation'],
          shipping_information: product_hash['shippingInformation'],
          availability_status: product_hash['availabilityStatus'],
          return_policy: product_hash['returnPolicy'],
          minimum_order_quantity: product_hash['minimumOrderQuantity'],
          meta: {
            created_at: product_hash.dig('meta', 'createdAt'),
            updated_at: product_hash.dig('meta', 'updatedAt'),
            barcode: product_hash.dig('meta', 'barcode'),
            qr_code: product_hash.dig('meta', 'qrCode')
          },
          images: product_hash['images'],
          reviews: reviews_array
        }

        if product.save
          total_products += 1
        else
          Rails.logger.error("Failed to save product #{product.id}: #{product.errors.full_messages}")
        end
      end

      Rails.logger.info("Successfully fetched and saved #{total_products} products")

    rescue StandardError => e
      Rails.logger.error("FetchProductsJob failed: #{e.class} - #{e.message}")
    end
  end
end
