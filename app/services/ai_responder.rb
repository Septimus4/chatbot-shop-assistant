# frozen_string_literal: true

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
  SYSTEM

  def self.call(chat:, user_message:)
    catalog_context   = build_catalog_snippet(chat)
    history_messages  = build_history(chat)

    messages = [
      { role: "system",    content: PROMPT },
      { role: "system",    content: catalog_context.presence || "No catalog context." },
      *history_messages,
      { role: "user",      content: user_message }
    ]

    response = OpenAIClient.chat(
      parameters: {
        model:       "gpt-4o-mini",
        temperature: 0.7,
        messages:    messages
      }
    )

    response.dig("choices", 0, "message", "content")
  end

  # --------------------------------------------------------------------------
  private_class_method

  def self.build_catalog_snippet(product_ids)
    Product.where(id: product_ids).limit(10).map(&:to_prompt_line).join("\n")
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
end
