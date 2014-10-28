namespace :feed_retweeter do

	task :run => :environment do
		RssFeedCollection.all.each do |rfc|
			user = rfc.user
			twitter_client = user.twitter_client
			rfc.rss_feeds.each do |rsf|

				# get rss tweet without random hashtag
				# to see if this tweet has been tweeted before
				tweet = rsf.rss_tweet

				unless Record.where(text: tweet, record_type: "Tweet").exists?
					tweet = rsf.generate_rss_tweet
					user.tweet(tweet)
					Record.create!(text: tweet, rss_feed_collection_id: rfc.id, record_type: "Tweet")
				end
			end
		end
	end
end