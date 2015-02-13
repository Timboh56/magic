class AugurProfilesController < ApplicationController
	skip_before_filter :verify_authenticity_token, only: [ :create ]

	def create
		p params.inspect
		AugurProfile.create!(data: params, person_id: Person.where(twitter_screen_name: params[:PROFILES][:twitter_handle][0][:value]).first.id) rescue nil
		render nothing: true
	end
end