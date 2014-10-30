namespace :followers do

	task :unfollow => :environment do
		TwitterBlast.all.each do |twitter_blast|
			twitter_blast.follows.each do |follow|
				
			end
		end
	end
end