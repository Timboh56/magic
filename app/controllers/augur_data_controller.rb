class AugurDataController < ApplicationController
	def create
		p params.inspect
		AugurData.create!(data: params[:augur_data], person_id: Person.where(twitter_screen_name: params[:handle]).first.id)
	end
end