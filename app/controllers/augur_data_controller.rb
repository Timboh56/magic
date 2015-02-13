class AugurDataController < ApplicationController
	skip_before_filter :verify_authenticity_token, only: [ :create ]

	def create
		p params.inspect
		AugurData.create!(data: params, person_id: Person.where(twitter_screen_name: params[:PROFILES][:handle]).first.id)
		render nothing: true
	end
end