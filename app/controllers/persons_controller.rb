class PersonsController < ApplicationController
  skip_before_filter :verify_authenticity_token, only: [ :tutor_lookup ]

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
    p = Person.create!(
      google_id: params[:google_id],
      email: params[:email],
      name: params[:name]
    )
    render json: p
  end
end