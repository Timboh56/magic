namespace :followers do

	task :run => :environment do
		TwitterBlast.all.each do |twitter_blast|
			twitter_blast.follows.each do |follow|
				follow.text
			end
		end
	end
end