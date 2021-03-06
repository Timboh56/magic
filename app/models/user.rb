class User
  include Mongoid::Document
  include Mongoid::Timestamps
  include ScrapeHelpers
  include TwitterHelpers
  require "timeout"

  field :uid, type: String
  field :provider, type: String # Facebook or Twitter
  field :name, type: String
  field :oauth_token, type: String
  field :oauth_secret, type: String
  field :role, type: String, default: "registered" # "registered", "admin"
  field :direct_message, type: String
  field :phone_number, type: String
  field :tinder_auth_token, type: String
  field :email, type: String
  field :unfollowing, type: Boolean, default: false
  field :follower_count
  field :following_count

  has_many :twitter_blasts
  has_many :rss_feed_collections
  has_many :records
  has_many :craig_crams

  has_one :people_scrape
  has_one :user_tinder_bot

  default_scope lambda{ includes(:records).order(:created_at => :desc) }

  accepts_nested_attributes_for :rss_feed_collections

  def twitter_user?
    provider == "twitter"
  end

  def facebook_user?
    provider == "facebook"
  end

  # run background task for unfolow
  def enqueue_unfollow
    Resque.enqueue(UserWorker, id, "unfollow_following_not_followers")    
  end

  def unfollow_following_not_followers

    # get list of followers
    followers_list = followers_list_stringified
    
    # get list of following
    following_list = following_list_stringified

    rate_limit = following_list.count > 2000 ? TwitterHelpers::UNFOLLOW_LIMIT :  TwitterHelpers::UNFOLLOW_LIMIT_UNDER_2000

    # unfollow handles on following not on followers
    (following_list - followers_list).take(rate_limit).each do |handle|

      p "Unfollowing " + handle.to_s

      unfollow(handle)
      
      r = Record.create!({
        text: handle,
        record_type: "Unfollow",
        user_id: id
      })

      sleep_random
    end
  end

  def direct_message_followers(messages, handle = nil, twitter_blast = nil)
    handle ||= name

    # get count of all DMs sent so far today from user
    dm_count = todays_direct_messages_count

    limit = twitter_blast.limit || TwitterHelpers::DIRECT_MESSAGE_LIMIT
  
    # get list of followers of user, limit to 250
    get_followers_or_following("followers", handle, twitter_blast).each do |follower|
      
      if dm_count > limit
        p "More handles direct messaged than daily limit! Stopping.."
        break
      end

      # for each direct message, send
      messages.each do |msg|

        dm_params = {
          user_id: id,
          record_type: "DirectMessage",
          to: follower.screen_name,
          twitter_blast_id: twitter_blast.id,
          text: msg.text
        }

        unless records.direct_messages.where(dm_params).exists?
          
          send_direct_message(follower.screen_name, msg.text)
          
          Record.create!(dm_params)
          
          p "Direct message: #{ msg.text }"
          p "Sent to: #{ follower.screen_name } "

          if twitter_blast
            twitter_blast.messages_sent += 1
            twitter_blast.save!
          end

          # increment todays DM count
          dm_count += 1

        end
      end

      sleep_random

    end
  end

  # return array of handles of each 
  # user that followedget_followers_or_following back
  def followers_list_stringified(handle = nil)
    handle ||= name
    get_followers_or_following("followers", handle).map! { |f| f.screen_name }
  end

  # return array of handles of each record of
  # user followed
  def following_list_stringified(handle = nil)
    handle ||= name
    get_followers_or_following("friends", handle).map! { |f| f.screen_name }
  end


  def handle_lists
    twitter_blasts.select { |t| t.handle_list }
  end

  def admin?
    role === "admin"
  end

  def self.from_omniauth(auth)
    if (user = where(auth.slice("provider", "uid")).first)
      user.update_from_omniauth!(auth)
      user
    else
      create_from_omniauth(auth)
    end
  end

  def update_from_omniauth!(auth)
    self.email = auth["info"]["email"]
    self.oauth_token = auth["credentials"]["token"]
    self.oauth_secret = auth["credentials"]["secret"]
    save!
  end
  
  def self.create_from_omniauth(auth)
    create! do |user|
      user.provider = auth["provider"]
      user.uid = auth["uid"]
      user.email = auth["info"]["email"]
      user.name = auth["info"]["nickname"] || auth["info"]["name"]
      user.oauth_token = auth["credentials"]["token"]
      user.oauth_secret = auth["credentials"]["secret"]
    end
  end

  def twitter_client
    if provider == "twitter"
      @twitter ||= Twitter::REST::Client.new do |config|
        config.access_token = oauth_token
        config.access_token_secret = oauth_secret
        config.consumer_key = Rails.application.config.twitter_key
        config.consumer_secret = Rails.application.config.twitter_secret
      end
      return @twitter
    end
    return nil
  end

  def twilio_client
    @twilio_client ||= Twilio::REST::Client.new ENV["TWILIO_ACCOUNT_SSID"], ENV["TWILIO_AUTH_TOKEN"]
  end

  def user_lookup(handle = nil)
    handle ||= name
    u = twitter_client.user(handle)
  end

  def send_sms(to, message_body, from = nil)
    from = from || phone_number
    [from, to].each { |n| n.gsub!(/\D/m,"") }

    status = Timeout::timeout(5) {
      twilio_client.messages.create(
        from: "+1#{from}",
        to: "+1#{to}",
        body: message_body
      )
      p "Message sent from #{ from } to #{ to }: #{ message_body }"
    }

    p status
  rescue Exception => e
    p e.inspect
  end

  def following_count(handle = nil)
    user_lookup(handle).friends_count
  end

  # return number of followers
  def follower_count(handle = nil)
    user_lookup(handle).friends_count
  end

  def detect_follow_respond(&block)
    twitter_streaming_client.user do |object|
      case object
      when Twitter::Streaming::Event
        yield if block_given? && object.name == "follow"
      end
    end
  end

  def send_direct_message(handle, text)
    twitter_client.create_direct_message(handle, text)
  end

  def twitter_streaming_client

    if provider == "twitter"
      @streaming_client ||= Twitter::Streaming::Client.new do |config|
        config.access_token = oauth_token
        config.access_token_secret = oauth_secret
        config.consumer_key = Rails.application.config.twitter_key
        config.consumer_secret = Rails.application.config.twitter_secret
      end
    end
    @streaming_client
  end

  def get_followers_or_following(followers_or_friends, handle = nil, twitter_blast = nil, store = false)
    handles = []
    handle ||= name

    if followers_or_friends == "followers"
      results = twitter_client.follower_ids(handle).to_a
    else
      results = twitter_client.friend_ids(handle).to_a
    end

    p "Getting #{ followers_or_friends } of: #{ handle.to_s }"

    puts results.length

    results.each_slice(100).each do |uids|

      p "Batch of 100"

      user_profiles = twitter_client.users(uids)

      user_profiles.each do |u|

        p "Got #{ followers_or_friends } information: " + u.screen_name
      
        record_params = {
          record_type: "Handle",
          text: u.screen_name,
          user_id: id
        }

        if store
          unless (record = Record.where(record_params).first).present?

            record_params.merge!({
              twitter_blast_id: twitter_blast.id,
              handle_list_id: (twitter_blast.handle_list ? twitter_blast.handle_list.id : nil)
            }) if twitter_blast

            # create a record
            record = Record.create!(record_params)
          
            p "Created record: " + record.inspect
          end
        end

        handles << u
      end
    end
    handles
  rescue Twitter::Error::TooManyRequests => error
    p error
    p 'Sleep ' + error.rate_limit.reset_in.to_s
    sleep error.rate_limit.reset_in
    retry
  end

  def tweet(message)
    response = twitter_client.update(message)
    message
  end

  def todays_tweets_count
    @todays_tweets_count ||= records.tweets.created_today.count
  end

  def todays_direct_messages_count
    @todays_direct_messages_count ||= records.direct_messages.created_today.count rescue 0
  end

  def todays_follow_count
    @todays_follow_count ||= records.follows.created_today.count
  end

  def unfollow(handle)
    twitter_client.unfollow(handle)
  end

  def follow(handle)
    twitter_client.follow!(handle)
    p "Followed: " + handle.inspect
  end

  def rss_feeds
    if rss_feed_collections.present?
      rss_feed_collections.inject([]) { |arr,collection| arr.concat collection.rss_feeds }
    end
  end
end