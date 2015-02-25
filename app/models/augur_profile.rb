class AugurProfile
	include Mongoid::Document

	field :data, type: Hash
	belongs_to :person

	def self.set_person_data

		Person.where(facebook_screen_name: nil).with_twitter.each do |person|
		AugurProfile.all.each do |a|
			person = a.person

			if a.data["PRIVATE"]
				person.email = a.data["PRIVATE"]["email"] if person.email.nil?
			end
			if a.data["PROFILES"]
				person.facebook_screen_name = a.data["PROFILES"]["facebook_handle"] if person.facebook_screen_name.nil?
				person.linkedin_screen_name = a.data["PROFILES"]["linkedin_handle"] if person.linkedin_screen_name.nil?
			end
			if person.changed?
				person.save!
				p "saved!"
			end

		end
	end
end