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
	task :craig_cram => :environment do
		CraigCram.all.each do |cram_job|
			cram_job.run
		end

	end

	# run daily
	task :follow => :environment do
		TwitterBlast.follow_handles.each do |twitter_blast|
			twitter_blast.run
		end
	end

	# run every hour
	task :get_feeds => :environment do
		RssFeedCollection.all.each do |rfc|
			rfc.post_from_latest_rss
		end
	end

	task :direct_message_tinder_matches => :environment do
		UserTinderBot.all.each do |utb|
			utb.dm_matches
		end
	end
end