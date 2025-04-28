class ChatsController < ApplicationController
  before_action :authenticate_user!

  def index
    @chats = current_user.chats.order(updated_at: :desc)
  end

  def show
    @chat = Chat.find(params[:id])
    @messages = @chat.messages.order(created_at: :asc)
  end

  def new
    @chat = Chat.new(user: current_user)
  end

  def create
    @chat = current_user.chats.build(started_at: Time.current)

    if @chat.save
      respond_to do |format|
        format.html { redirect_to chat_path(@chat), notice: "Chat started successfully." }
        format.turbo_stream { redirect_to chat_path(@chat), notice: "Chat started successfully." }
      end
    else
      puts @chat.errors.full_messages
      respond_to do |format|
        format.html { render :new, alert: "Failed to create chat." }
        format.turbo_stream { render :new, status: :unprocessable_entity }
      end
    end
  end
end
