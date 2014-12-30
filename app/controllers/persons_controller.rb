class PersonsController < ApplicationController
  skip_before_filter :verify_authenticity_token, only: [ :tutor_lookup, :tutor_create ]

  def emails

  end

  def lookup
    Resque.enqueue(ClearbitWorker, params[:emails].split(/,|\n/))
    render "/persons/lookup.js"
  end

  def tutor_lookup
  	p = Person.where(available: true).first
  	render json: p
  end

  def tutor_create
    unless (p = Person.where(google_id: params[:google_id]).first).present?
      p = Person.create!(
        google_id: params[:google_id],
        email: params[:email],
        name: params[:name],
        phone: params[:number],
        person_type: "Tutor"
      )
    end
    render json: p
  end
end