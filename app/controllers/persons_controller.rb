class PersonsController < ApplicationController

  def emails

  end
  def lookup
    params[:emails].split(/\,|\/n|\/r/).each do |email|
    	Clearbit.key = ENV["CLEARBIT_API_KEY"]
      person = Clearbit::Person[email: email, subscribe: true]
      if person && !person.pending?
        puts "Name: #{person.name.fullName}"
      end
    end
    render "/persons/lookup.js"
  end
end