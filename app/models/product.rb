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

  def self.search_by_keywords(keywords)
    return Product.none if keywords.blank?

    adapter = ActiveRecord::Base.connection.adapter_name.downcase
    cleaned_keywords = keywords.map { |k| k.gsub(/[^a-zA-Z0-9]/, '') }.reject(&:blank?)

    if adapter.include?("postgresql")
      ts_query = cleaned_keywords.join(" | ")
      where("to_tsvector('simple', coalesce(title, '') || ' ' || coalesce(description, '')) @@ to_tsquery(?)", ts_query)
    else
      # SQLite fallback: build OR query
      conditions = cleaned_keywords.map do |kw|
        "title LIKE :kw_#{kw} OR description LIKE :kw_#{kw}"
      end
      where(conditions.join(" OR "), **cleaned_keywords.to_h { |kw| ["kw_#{kw}".to_sym, "%#{kw}%"] })
    end
  end
end
