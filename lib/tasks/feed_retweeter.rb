namespace :feed_retweeter do

	task :retweet_rss_feeds => :environment do
		Record.rss_feeds.each do |rss_feed|
			response = Feedjira::Feed.fetch_and_parse(rss_feed.text)

		end
	end
end