class AngelScrape
	include Mongoid::Document
	field :user_index, default: 1

	def run
		angels = AngellistApi.get_users([*user_index..(user_index + 50)])
		angels.each do |angel|
			begin
				Person.create!(bio: angel.bio, name: angel.name, angellist_info: angel.to_hash)
			rescue Exception => e
				p e.inspect
			end
		end
		self.user_index += 1
		run
	rescue Exception => e
		p "Exception: #{ e.inspect }, stopping.."
	end
end