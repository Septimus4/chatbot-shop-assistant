class MessagesController < ApplicationController
  before_action :authenticate_user!

  def create
    @chat = Chat.find(params[:chat_id])

    # 1. store the human message
    user_msg = @chat.messages.create!(
      content: message_params[:content],
      sender_type: :user,
      user: current_user
    )

    # 2. ask OpenAI
    assistant_text = AiResponder.call(
      chat: @chat,
      user_message: user_msg.content
    )

    # 3. store the AI reply
    @chat.messages.create!(
      content: assistant_text,
      sender_type: :ai
    )

    redirect_to chat_path(@chat)
  end

  private

  def message_params
    params.require(:message).permit(:content)
  end
end
