# Sparky AI Responder

**Sparky** is a virtual shopping assistant designed for the **SuperAI Shop** — an online store selling electronics, gadgets, gaming gear, and lifestyle accessories.  
This AI agent provides friendly, intelligent customer support, product recommendations, and checkout handling.

---

## Setup

1. **Environment Configuration**  
   Set your OpenAI API key in your environment variables:
   ```bash
   export OPENAIKEY="your-openai-api-key"
   ```

2. **Populate Database with Inventory and Products**  
   Fetch external product data and load it into your database:
   ```bash
   rails c
   FetchProductsJob.perform_now
   ```

---

## Features and Capabilities

- **Warm, Helpful Interactions**  
  Greets customers warmly, asks clarifying questions, and keeps a friendly and upbeat tone throughout the conversation.

- **Smart Product Recommendations**  
  Suggests relevant products based on:
    - Explicit product IDs found in conversation history.
    - Keywords extracted intelligently from the customer's message (using stemming and stopword filtering).
    - Promotions and key specs are highlighted concisely.

- **Order Assistance and Checkout**  
  Guides the customer through placing an order:
    - Collects product choices, quantity, phone number, address, postcode, etc.
    - Generates a clean, strict JSON payload for order creation without extra text.

- **Error Handling**  
  If the AI responds with invalid JSON or missing order fields, it gracefully returns helpful error messages.

- **Safe and Trustworthy**
    - Never invents facts when catalog data is missing.
    - Politely declines illegal or inappropriate requests.
    - Keeps customer interactions concise (2–4 sentences unless more detail is requested).

- **Context Awareness**  
  Includes:
    - Logged-in user context (name, email).
    - Previous conversation snippets (up to 6 latest messages) to maintain coherent conversations.

---

## Technical Overview

- **Prompt Engineering**  
  The agent is initialized with a detailed system prompt defining tone, behavior, goals, and JSON output expectations.

- **Message Construction**  
  Builds a full conversation history before sending it to OpenAI's `gpt-4o-mini` model, including:
    - System prompts (agent behavior, user context, catalog snippets).
    - Chat history (up to the last 6 messages).
    - The latest user input.

- **Keyword Extraction**
    - Uses `Lingua::Stemmer` for stemming English words.
    - Filters out common stopwords to identify the key search terms.

- **Catalog Context Building**  
  Based on product IDs and/or keywords:
    - Searches products.
    - Builds a mini-catalog prompt for the model to reference (up to 10 items).

- **Order Creation Flow**
    - Parses the AI's JSON response.
    - Validates product IDs, quantities, and user presence.
    - Creates shipping addresses if needed.
    - Places the final order linked to the user.

- **Error Logging**  
  All unexpected errors during order creation are logged using Rails logger for traceability.

---

## Roadmap

The Sparky agent is fully functional but there are known areas for future improvement:

- **Address Handling Improvement**
    - *Current behavior*: Even when the user already has one or more saved addresses, Sparky still asks for a full new address during checkout.
    - *Planned upgrade*:  
      Introduce logic to detect existing user addresses and allow the user to:
        - Select from previously saved addresses.
        - Add a new address only if necessary.

- **Product ID Memory Across Conversation**
    - *Current behavior*: Product IDs mentioned earlier in the conversation are not properly remembered.  
      If the user refers to previously discussed products at checkout time, the AI may miss them, causing ordering errors.
    - *Planned upgrade*:  
      Implement memory/context persistence for selected product IDs during a session, ensuring accurate order building based on prior product selection or discussion.
