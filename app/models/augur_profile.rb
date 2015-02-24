class AugurProfile
	include Mongoid::Document

	field :data, type: Hash
	belongs_to :person

	def self.fix
		AugurProfile.all.each do |a|
			person = a.person
			if a.data["PRIVATE"]
				person.email = a.data["PRIVATE"]["email"]
			end
			if a.data["PROFILES"]
				person.facebook_screen_name = a.data["PROFILES"]["facebook_handle"]
				person.linkedin_screen_name = a.data["PROFILES"]["linkedin_handle"]
			end
			person.save!
			p "saved!"
		end

	end
end