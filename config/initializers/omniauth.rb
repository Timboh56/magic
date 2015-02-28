OmniAuth.config.logger = Rails.logger

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :twitter, ENV["DOPE_TWITTER_CONSUMER_KEY"], ENV["DOPE_TWITTER_SECRET"]
  provider :facebook, ENV["DOPE_FACEBOOK_APP_ID"], ENV["DOPE_FACEBOOK_SECRET"]
	provider :linkedin, "75jasbl9sxycjh", "M8GjAeURO2gdlYG5"
end