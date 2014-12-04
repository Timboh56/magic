class UserTinderBotsController < ApplicationController
  require 'tinderbot'
  def dm_matches


  end

  def index
    @tinderbot = current_user.user_tinder_bot || UserTinderBot.new
  end

  def get_matches

  end

  def show
    @user_tinder_bot = UserTinderBot.find(params[:id])
  end

  def create
    @user_tinder_bot = UserTinderBot.new(user_tinder_bot_params)
    @user_tinder_bot.user_id = current_user.id
    if @user_tinder_bot.save
      @user_tinder_bot.enqueue_task("like_recommended_users")
    else
      p "An error occurred: #{ @user_tinder_bot.errors.inspect }"
    end
    redirect_to "/tinder_bot"
  end

  def update
    current_user.user_tinder_bot.update_attributes!(user_tinder_bot_params)
    current_user.user_tinder_bot.enqueue_task("like_recommended_users")
    redirect_to "/tinder_bot"
  end

  private

  # Never trust parameters from the scary internet, only allow the white list through.
  def user_tinder_bot_params
    params.require(:user_tinder_bot).permit(
      :autolike, :message, :status, :fb_access_token, :lat, :long,
      :messages_attributes => [ :text, :id, :_id, :_destroy ]
    )
  end
end