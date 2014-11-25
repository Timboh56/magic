module RateLimits

	# daily rate limits on twitter

	UNFOLLOW_LIMIT = 1000
	FOLLOW_LIMIT = 1000
	FOLLOW_LIMIT_UNDER_2000 = 700
	UNFOLLOW_LIMIT_UNDER_2000 = 1000
	TWEET_LIMIT = 2400
	DIRECT_MESSAGE_LIMIT = 1000

  def sleep_random
    sleep(rand(5))
  end
end