namespace :twitter do

	task :detect_follows_respond => :environment do
		TwitterBlast.all.each do |twitter_blast|

		end
	end

	# for each twitter blast 
	task :clean_followers => :environment do
		

	end

	task :direct_message_follow_backs => :environment do
		TwitterBlast.follow_handles.each do |twitter_blast|
			twitter_blast.direct_message_follow_backs
		end
	end
end