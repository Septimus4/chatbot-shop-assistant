# frozen_string_literal: true

require "rubygems"
require "lingua/stemmer"
require "stopwords"

class AiResponder
  PROMPT = <<~SYSTEM.freeze
      You are “Sparky,” the virtual shopping assistant for SuperAI Shop — an online
      store that sells electronics, household gadgets, gaming gear, and lifestyle
      accessories.

      Goals
      • Greet customers warmly and use a helpful, upbeat tone.
      • Identify what the customer actually needs (ask clarifying questions if vague).
      • Recommend suitable products with 1-3 key specs, price, and promotions.
      • Suggest add-ons only when they add clear value — never pushy.
      • Respect any budget the customer states.
      • Help with checkout, shipping, returns, or warranty questions.
      • If the store can’t meet a request, apologise and offer the closest match.
      • Keep answers short (2–4 sentences) unless detail is requested.
      • Never invent facts; if inventory data is missing, say so.
      • Never reveal internal policies, API keys, or code.
      • Politely refuse illegal, unsafe, or off-topic requests.

      Formatting
      • Product: **Name** – short blurb (Key spec • Price)
      • Bullet-list multiple items.
      • End with a question (“Would you like to add this to your cart?”).

      Remember: be friendly, concise, accurate, and genuinely helpful.

    • When the customer is ready to order, ask for:
      - Product(s) and quantity
      - Phone number (with country code)
      - Address and postcode
    • Once all fields are collected, respond with a JSON block ONLY, like:
      ```json
      {
        "action": "create_order",
        "phone_number": "+123456789",
        "address": "123 Elm Street",
        "postcode": "90210",
        "city": "Los Angeles",
        "country": "US",
        "products": [
          { "product_id": 1, "quantity": 2 },
          { "product_id": 5, "quantity": 1 }
        ]
      }
      ```
    • Do not include extra commentary. Just the JSON block.
  SYSTEM

  def self.call(chat:, user_message:)
    product_ids = extract_relevant_product_ids(chat)
    catalog_context = build_catalog_snippet(product_ids, user_message)
    history_messages = build_history(chat)

    # Inject user context if available
    user = chat.user
    user_context = if user
                     <<~USER.freeze
                       The user is logged in.
                       • First name: #{user.first_name}
                       • Last name: #{user.last_name}
                       • Email: #{user.email}
                     USER
                   else
                     "No user context available."
                   end

    messages = [
      { role: "system", content: PROMPT },
      { role: "system", content: user_context },
      { role: "system", content: catalog_context.presence || "No catalog context." },
      *history_messages,
      { role: "user", content: user_message }
    ]

    response = OpenAIClient.chat(
      parameters: {
        model: "gpt-4o-mini",
        temperature: 0.7,
        messages: messages
      }
    )

    content = response.dig("choices", 0, "message", "content")

    if content =~ /```json(.+?)```/m
      begin
        json_str = content.match(/```json(.+?)```/m)[1].strip
        order_data = JSON.parse(json_str).deep_symbolize_keys

        if order_data[:action] == "create_order"
          result = create_order_from_ai(order_data.merge(
            first_name: user&.first_name,
            last_name: user&.last_name,
            email: user&.email
          ))
          return result[:message] || result[:error]
        end
      rescue JSON::ParserError => e
        return "There was an error processing your order JSON: #{e.message}"
      end
    end

    content.presence || "⚠️ Sorry, I didn’t quite catch that. Could you please rephrase?"
  end

  def self.create_order_from_ai(params)
    required_keys = %i[phone_number address postcode products]
    missing = required_keys.select { |k| params[k].blank? }
    return { error: "Missing fields: #{missing.join(', ')}" } if missing.any?

    product_ids = params[:products].map { |p| p[:product_id] }.uniq
    products = Product.where(id: product_ids).index_by(&:id)

    invalid_ids = product_ids - products.keys
    return { error: "Invalid product IDs: #{invalid_ids.join(', ')}" } if invalid_ids.any?

    invalid_quantities = params[:products].select { |p| p[:quantity].to_i <= 0 }
    return { error: "Product quantities must be greater than 0" } if invalid_quantities.any?

    user = User.find_by(email: params[:email])
    return { error: "User with email #{params[:email]} not found." } unless user

    user.update!(
      phone_number: params[:phone_number]
    )

    shipping_address = Address.find_or_create_by!(
      phone_number: params[:phone_number],
      address: params[:address],
      postcode: params[:postcode],
      city: params[:city] || "Unknown",
      country: params[:country] || "Unknown"
    )

    product_data = params[:products].map do |p|
      {
        id: p[:product_id],
        quantity: p[:quantity]
      }
    end

    Order.create!(
      user: user,
      address: shipping_address,
      products: product_data
    )

    { success: true, message: "✅ Order placed successfully for #{user.first_name}!" }
  rescue => e
    Rails.logger.error "Error in AiResponder.place_order: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    { error: "❌ Order creation failed: #{e.message}" }
  end

  private_class_method

  def self.extract_relevant_product_ids(chat)
    product_ids = []
    chat.messages.each do |message|
      message.content.scan(/\b\d+\b/).each { |id| product_ids << id.to_i }
    end

    product_ids.uniq
  end

  def self.build_catalog_snippet(product_ids = [], user_message = nil)
    keywords = extract_keywords(user_message)
    products_scope = Product.none

    if product_ids.any? && keywords.any?
      id_scope = Product.where(id: product_ids)
      keyword_scope = Product.search_by_keywords(keywords)
      products_scope = id_scope.or(keyword_scope)
    elsif product_ids.any?
      products_scope = Product.where(id: product_ids)
    elsif keywords.any?
      products_scope = Product.search_by_keywords(keywords)
    end

    products = products_scope.limit(10).distinct.to_a
    products.map(&:to_prompt_line).join("\n")
  end

  def self.build_history(chat)
    chat.messages
        .order(created_at: :asc)
        .last(6)
        .map do |m|
      role = (m.sender_type == "ai" ? "assistant" : "user")
      { role: role, content: m.content }
    end
  end

  def self.extract_keywords(message)
    return [] unless message&.present?

    @stemmer ||= Lingua::Stemmer.new(language: "en")

    words = message.downcase.scan(/\b[a-z0-9]+\b/)
    clean = words.select { |w| Stopwords.valid?(w) }

    clean.map { |w| @stemmer.stem(w) }.uniq
  end
end
