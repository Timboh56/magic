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
  	render :json => p.to_json
  end
end