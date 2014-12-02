class UserTinderBot
  include Mongoid::Document
  include Mongoid::Timestamps
  require 'tinderbot'


  field :autolike, type: Boolean, default: false
  field :message, type: String
  field :status, type: String

  belongs_to :user

  def tinder_bot
    @tinder_bot ||= Tinderbot::Bot.new tinder_client
  end

  def signin(password)
    facebook_authentication_token, facebook_user_id = Tinderbot::Facebook.get_credentials user.email, password
    tinder_authentication_token = tinder_client.get_authentication_token facebook_authentication_token, facebook_user_id
    user.update_attributes!(tinder_auth_token: tinder_authentication_token )
    tinder_client.sign_in tinder_authentication_token
  end

  def tinder_client
    @tinder_client ||= Tinderbot::Client.new({ logs_enabled: true })
  end

  def enqueue_task(action) 
  	Resque.enqueue(TinderBotWorker, id, action)
  end

  def like_recommended_users
  	@tinder_bot.like_recommended_users
  end
end