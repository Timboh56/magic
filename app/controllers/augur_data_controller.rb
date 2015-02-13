class AugurDataController < ApplicationController

	def create
		AugurData.create!(params[:augur_data])
	end
end