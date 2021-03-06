class PeopleController < ApplicationController
  skip_before_filter :verify_authenticity_token, only: [ :tutor_lookup, :tutor_create ]
  respond_to :html, :js, :csv

  def lookup
    Resque.enqueue(ClearbitWorker, params[:emails].split(/,|\n/))
    render "/persons/lookup.js"
  end

  def tutor_lookup
  	p = Person.where(available: true, person_type: "Tutor").first
  	render json: p
  end

  def index

  end

  def investors
    respond_to do |format|
      format.csv do
        send_data Person.investors_csv
      end
      format.xls
      format.html
    end
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