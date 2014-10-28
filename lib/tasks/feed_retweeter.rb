namespace :feed_retweeter do

	task :retweet_rss_feeds => :environment do
		RssFeedCollection.all.each do |rfc|
			user = rfc.user
			twitter_client = user.twitter_client
			rfc.rss_feeds.each do |rsf|
				user.tweet(rsf.generate_rss_tweet)
				Record.create!(rss_feed_collection_id: rfc.id, record_type: "Tweet")
			end
		end
	end
end