module TwitterHelper
	def twitter_client
		client = Twitter::REST::Client.new do |config|
		  config.consumer_key    = "k835HQO0vkJuseCB2b0QMGOhR" || ENV["TWITTER_CONSUMER_KEY"]
		  config.consumer_secret = "3VywVRrvOv3C6SGyhjzuuHH3M4xTPyqEImD4omYSGTuQJhaC5Z" || ENV["TWITTER_CONSUMER_SECRET"]
		end
	end
end