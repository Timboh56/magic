class AugurProfilesController < ApplicationController
	skip_before_filter :verify_authenticity_token, only: [ :create ]

	def create
		p params.inspect
		if params[:status] == 200
			if params[:PROFILES] && params[:PROFILES][:twitter_handle]
				p params[:PROFILES][:twitter_handle].to_s
				if params[:PROFILES][:twitter_handle].is_a? Array
					a = AugurProfile.create!(data: params, person: Person.where(twitter_screen_name: /#{params[:PROFILES][:twitter_handle][0][:value]}/i).first.id) rescue nil
				else
					a = AugurProfile.create!(data: params, person: Person.where(twitter_screen_name: /#{params[:PROFILES][:twitter_handle]}/i).first.id) rescue nil
					if params[:PRIVATE] && params[:PRIVATE][:email]
						a.person.update_attribute(email: params[:PRIVATE][:email])
					end
				end

			end
			render nothing: true
		else
			p "Received a status of: " + params[:status].to_s
			render nothing: true, status: 420
		end
	end
end