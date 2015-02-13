class AugurProfilesController < ApplicationController
	skip_before_filter :verify_authenticity_token, only: [ :create ]

	def create
		p params.inspect
		if params[:PROFILES] && params[:PROFILES][:twitter_handle]
			p params[:PROFILES][:twitter_handle].to_s
			if params[:PROFILES][:twitter_handle].is_a? Array
				AugurProfile.create!(data: params, person_id: Person.where(twitter_screen_name: params[:PROFILES][:twitter_handle][0][:value]).first.id) rescue nil
			else
				AugurProfile.create!(data: params, person_id: Person.where(twitter_screen_name: params[:PROFILES][:twitter_handle]).first.id) rescue nil
			end

		end
		render nothing: true
	end
end