class Product < ApplicationRecord
  validates :title, :description, :category, :price, presence: true

  def to_prompt_line
    <<~TEXT.squish
      • #{title} — #{short_description} (#{key_specs} • $#{price})
    TEXT
  end

  private

  def short_description
    description.to_s.split(".").first
  end

  def key_specs
    specs = []
    specs << "#{rating}★ rating" if rating.present?
    specs << "#{stock} in stock" if stock.present?
    specs << "Brand: #{brand}" if brand.present?
    specs.join(" • ")
  end
end
