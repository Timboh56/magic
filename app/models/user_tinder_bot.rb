class UserTinderBot
  include Mongoid::Document
  include Mongoid::Timestamps
  include ScrapeHelpers
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

  def dm_matches_with_convos(msg)
    signin
    matches_with_convos = get_matches.select { |match| match["messages"].present? }
    matches_with_convos.each do |match|
      dm_match(match["_id"], msg)
    end
  end

  def dm_matches(msg = nil)
    signin
    unless messages.empty? && msg.nil?
      get_matches.each do |match|
        if messages.present?
          messages.each { |m| dm_match(match["_id"], m) }
        else
          dm_match(match["_id"], msg)
        end
      end
    end
  rescue Exception => e
    "Error: #{ e.message }"
  end

  def dm_match(tinder_id, msg = nil)
    msg = msg.is_a? Message ? msg.text : msg
    params = { record_type: "TinderDM", text: msg, to: tinder_id, user_id: user.id }
    unless Record.where(params).exists?
      tinder_client.send_message(tinder_id, msg)
      Record.create!(params)
      sleep_random
    else
      p "Already sent a message to #{ tinder_id }, skipping.."
    end
  end

  def like_recommended_users
    tinder_bot.like_recommended_users
  rescue
    p "Retrying..."
    retry
  end
end