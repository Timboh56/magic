@client ||= Twitter::REST::Client.new do |config|
  config.consumer_key    = "1SzfIhMcCxz5UwfhT6RlC7hON" || ENV["TWITTER_CONSUMER_KEY"]
  config.consumer_secret = "smg6wZaOVcyTOp4dBQawnIE1E6XWs5SjCzemQXiK3r7gfiPYoL" || ENV["TWITTER_CONSUMER_SECRET"]
	config.access_token = "2214765794-1WkCygxJhhbvt8PJ0uf24tmcv9UfzV7HrsjPjEN"
	config.access_token_secret = "b2d7xptVILjHbn3EYJrSjGZOm14mNftyywNrK5xIew0hf"
end