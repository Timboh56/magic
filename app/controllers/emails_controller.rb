class EmailsController < ApplicationController
	def create
		@email = Email.create(email_params)
	end

	private

	def email_params
		params.require(:email).permit(:email, :name, :password)
	end
end