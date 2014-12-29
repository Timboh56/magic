class UserMailer < ActionMailer::Base
  default from: "from@example.com"

  def send_email(email)
  	if email.is_a? Email
  		@email = email.email
  		@body = email.body
  		@name = email.name
  		mail(to: "tim@colab.la", from: @email, subject: 'New Email from #{ @name }')
  	else
  		raise "You did not pass an email object."
  	end
  end
end
