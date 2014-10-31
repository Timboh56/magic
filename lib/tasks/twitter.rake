namespace :twitter do

	# run daily
	task :direct_message_followers => :environment do
		TwitterBlast.follow_handles.each do |twitter_blast|
			twitter_blast.direct_message_followers
		end
	end

	# run weekly
	task :unfollow_following_not_followers => :environment do

		# only run on fridays, weekly job
		if Time.now.friday? # previous answer: Date.today.wday == 5
			
			TwitterBlast.follow_handles.each do |twitter_blast|
				twitter_blast.unfollow_following_not_followers
			end
		end
	end
end