OmniAuth.config.logger = Rails.logger

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :twitter, ENV["DOPE_TWITTER_CONSUMER_KEY"], ENV["DOPE_TWITTER_SECRET"]
end
