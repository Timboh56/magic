class TinderBotWorker
  require "mechanize"
  require "pathname"
  require "resque/errors"
  @queue = :tinder_bot_worker

  class << self
    def perform(id, action)
      @user_tinder_bot = UserTinderBot.find(id)
      @user_tinder_bot.send(action)
    end
  end
end