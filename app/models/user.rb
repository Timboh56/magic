class User
  include Mongoid::Document
  include Mongoid::Timestamps

  field :uid, type: String
  field :provider, type: String
  field :name, type: String
  field :oauth_token, type: String
  field :oauth_secret, type: String

  has_many :rss_feed_collections

  accepts_nested_attributes_for :rss_feed_collections

  def self.from_omniauth(auth)
    where(auth.slice("provider", "uid")).first || create_from_omniauth(auth)
  end

  def update_from_omniauth!(auth)
    self.oauth_token = auth["credentials"]["token"]
    self.oauth_secret = auth["credentials"]["secret"]
    save!
  end
  
  def self.create_from_omniauth(auth)
    create! do |user|
      user.provider = auth["provider"]
      user.uid = auth["uid"]
      user.name = auth["info"]["nickname"]
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

  def get_followers(handle, twitter_blast = nil)
    followers = []
    results = twitter_client.follower_ids(handle).to_a

    p "Getting followers of: " + handle.to_s

    puts results.length

    results.each_slice(100).each do |follower_ids|

      p "Batch of 100"

      follower_profiles = twitter_client.users(follower_ids)

      follower_profiles.each do |follower|

        p "Got follower information: " + follower.screen_name
      
        record_params = {
          record_type: "Handle",
          text: follower.screen_name,
        }

        unless (record = Record.where(record_params).first).present?

          record_params.merge!({
            twitter_blast_id: twitter_blast.id,
            handle_list_id: twitter_blast.handle_list.id
          }) if twitter_blast

          # create a record
          record = Record.create!(record_params)
        
          p "Created record: " + record.inspect
        end

        followers << follower
      end
    end
    followers
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