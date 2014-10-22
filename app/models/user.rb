class User
  include Mongoid::Document
  include Mongoid::Timestamps

  field :uid, type: String
  field :provider, type: String
  field :name, type: String
  field :oauth_token, type: String
  field :oauth_secret, type: String

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
end