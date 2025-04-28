OpenAIClient = OpenAI::Client.new(
  access_token: ENV.fetch("OPENAIKEY")
)
