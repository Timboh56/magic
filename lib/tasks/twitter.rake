namespace :twitter do

	# for each twitter blast 
	task :clean_followers => :environment do


	end

	# run daily
	task :direct_message_followers => :environment do
		TwitterBlast.follow_handles.each do |twitter_blast|
			twitter_blast.direct_message_followers
		end
	end

	task :unfollow_following => :environment do
		TwitterBlast.all.each do |twitter_blast|
			twitter_blast.unfollow_following
		end
	end
end