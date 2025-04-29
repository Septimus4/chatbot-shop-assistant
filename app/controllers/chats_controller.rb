class ChatsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_chat, only: [:destroy]

  def index
    @chats = current_user.chats.order(updated_at: :desc)

    if params[:chat_id].present?
      @chat = current_user.chats.find_by(id: params[:chat_id])
      @messages = @chat&.messages&.order(:created_at) || []
    else
      @chat = nil
      @messages = []
    end
  end

  def create
    @chat = current_user.chats.build(started_at: Time.current)

    if @chat.save
      redirect_to chat_path(@chat), notice: "Chat started successfully."
    else
      Rails.logger.error(@chat.errors.full_messages)
      redirect_to chats_path, alert: "Failed to create chat."
    end
  end

  def destroy
    @chat.destroy
    redirect_to chats_path, notice: "Chat deleted successfully."
  end

  private

  def set_chat
    @chat = current_user.chats.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to chats_path, alert: "Chat not found."
  end
end
