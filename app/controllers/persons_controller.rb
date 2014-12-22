class PersonsController < ApplicationController

  def emails

  end

  def lookup
    Resque.enqueue(ClearbitWorker, params[:emails].split(/,|\n/))
    render "/persons/lookup.js"
  end
end