class TinderBotWorker
  require "mechanize"
  require "pathname"
  require "resque/errors"
  @queue = :tinder_bot_worker

  class << self
    def perform(obj_id, action)
      unless obj_id.is_a? String
        @user_tinder_bot = UserTinderBot.find(obj_id["$oid"])
      else
        @user_tinder_bot = UserTinderBot.find(obj_id)
      end
      @user_tinder_bot.signin
      @user_tinder_bot.send(action)
    end
  end
end