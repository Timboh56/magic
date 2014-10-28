namespace :feed_retweeter do

	task :run => :environment do
		RssFeedCollection.all.each do |rfc|
			user = rfc.user
			twitter_client = user.twitter_client
			rfc.rss_feeds.each do |rsf|
				tweet = rsf.generate_rss_tweet
				user.tweet(tweet)
				Record.create!(text: tweet, rss_feed_collection_id: rfc.id, record_type: "Tweet")
			end
		end
	end
end