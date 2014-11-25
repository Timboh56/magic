class SmsBlastsController < ApplicationController
	def text
		params[:phone_numbers].split(",").each do |phone_number|
			current_user.send_sms(phone_number, params[:text_message_body], params[:from_phone_number])
		end
	end
end