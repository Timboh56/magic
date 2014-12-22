# webhook_controller.rb
class WebhookController < ApplicationController
  skip_before_filter :verify_authenticity_token
  
  def emails

  end

  def clearbit
    if params[:type] == 'person' && params[:body]
      email  = params[:body][:email]
      person = (person = Person.where(email: email).first).present? ? person : Person.new(email: email)
      person.clearbit = params[:body]
      person.save
    end

    head :created
  end
end