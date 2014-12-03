class UserTinderBot
  include Mongoid::Document
  include Mongoid::Timestamps
  require 'tinderbot'


  field :autolike, type: Boolean, default: false
  field :message, type: String
  field :status, type: String
  field :fb_access_token, type: String

  belongs_to :user

  def tinder_bot
    @tinder_bot ||= Tinderbot::Bot.new tinder_client
  end

  def signin
    facebook_user_id = user.uid
    p user.uid
    p fb_access_token

    @client = tinder_client

    if user.tinder_auth_token
      tinder_authentication_token = user.tinder_auth_token
    else
      tinder_authentication_token = @client.get_authentication_token fb_access_token, facebook_user_id
    end
    
    p "Tinder authentication token: #{tinder_authentication_token}"
    user.update_attributes!(tinder_auth_token: tinder_authentication_token )
    @client.sign_in tinder_authentication_token
  end

  def tinder_client
    @tinder_client ||= Tinderbot::Client.new({ logs_enabled: true })
  end

  def enqueue_task(action)
    Resque.enqueue(TinderBotWorker, id.to_s, action)
  end

  def get_matches
    @matches ||= tinder_client.updates["matches"]
  end

  def dm_matches
    signin
    if message
      get_matches.each do |match|
        uid = match["_id"]
        tinder_client.send_message(uid, message)
      end
    end
  rescue Exception => e
    "Error: #{ e.message }"
  end

  def like_recommended_users
    tinder_bot.like_recommended_users
  rescue
    p "Retrying..."
    retry
  end
end