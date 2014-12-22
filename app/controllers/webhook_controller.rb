# webhook_controller.rb
class WebhookController < ApplicationController

  def emails
    
  end
  
  def clearbit
    if params[:type] == 'person' && params[:body]
      email  = params[:body][:email]
      person = Person.where(email: email).first

      if person
        person.clearbit = params[:body]
        person.save
      end
    end

    head 200
  end
end