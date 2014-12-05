class UserTinderBot
  include Mongoid::Document
  include Mongoid::Timestamps
  include TwitterHelpers
  require 'tinderbot'


  field :autolike, type: Boolean, default: false
  field :message, type: String
  field :status, type: String
  field :fb_access_token, type: String
  field :lat, type: String
  field :long, type: String 

  belongs_to :user
  has_many :messages

  accepts_nested_attributes_for :messages

  def update_location
    tinder_client.update_location("#{ lat }, #{ long }")
  end

  def tinder_bot
    @tinder_bot ||= Tinderbot::Bot.new tinder_client
  end

  def signin
    facebook_user_id = user.uid
    @client = tinder_client

    if user.tinder_auth_token
      tinder_authentication_token = user.tinder_auth_token
    else
      if fb_access_token
        tinder_authentication_token = @client.get_authentication_token fb_access_token, facebook_user_id
      else
        raise "FB Access Token is invalid"
      end
    end

    p "Tinder authentication token: #{tinder_authentication_token}"
    
    user.update_attributes!(tinder_auth_token: tinder_authentication_token )
    @client.sign_in tinder_authentication_token

    update_location if lat && long
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
    unless messages.empty?
      get_matches.each do |match|
        uid = match["_id"]
        messages.each do |m|
          params = { text: m.text, to: uid, user_id: user.id }
          unless Record.where(params).exists?
            tinder_client.send_message(uid, m.text)
            Record.create!(params)
          else
            p "Already sent a message to #{ uid }, skipping.."
          end
          sleep_random
        end
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