namespace :scheduler do

	# run daily
	task :direct_message_followers => :environment do
		TwitterBlast.follow_handles.each do |twitter_blast|
			twitter_blast.direct_message_followers
		end
	end

	# run every three days
	task :unfollow_following_not_followers => :environment do

		# run fridays, mondays, wednesdays
		if Time.now.sunday? || Time.now.monday? || Time.now.wednesday? || Time.now.friday?
			
			User.all.each do |user|
				user.enqueue_unfollow if unfollowing == true
			end
		end
	end

	# run daily
	task :follow => :environment do
		TwitterBlast.follow_handles.each do |twitter_blast|
			twitter_blast.run
		end
	end

	task :get_feeds => :environment do
		RssFeedCollection.all.each do |rfc|
			user = rfc.user
			rfc.rss_feeds.each do |rsf|

				# get rss tweet without random hashtag
				# to see if this tweet has been tweeted before
				tweet_no_tags = rsf.rss_tweet_no_tags

				unless Record.where(text: tweet_no_tags, record_type: "Tweet").exists?
					tweet = rsf.generate_rss_tweet
					user.tweet(tweet)
					Record.create!(text: tweet_no_tags, rss_feed_collection_id: rfc.id, record_type: "Tweet")
				end
			end
		end
	end

	task :direct_message_tinder_matches => :environment do
		UserTinderBot.all.each do |utb|
			utb.dm_matches
		end
	end
end