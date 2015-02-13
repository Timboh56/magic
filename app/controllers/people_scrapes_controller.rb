class PeopleScrapesController < ApplicationController
  def index
    @people_scrape = current_user.people_scrape || PeopleScrape.new
  end

  def create
  	@people_scrape = PeopleScrape.new(people_scrape_params)
  	@people_scrape.user_id = current_user.id
  	@people_scrape.save!
  	render "shared/success.js"
  end

  def update
  	@people_scrape = current_user.people_scrape
    if params[:people_scrape][:keywords] != @people_scrape.keywords
      @people_scrape.page_index = 1 # reset page index if
    end

    @people_scrape.assign_attributes(people_scrape_params)

    @people_scrape.save!

  	render "shared/success.js"
  end

  def people_scrape_params
  	params.require(:people_scrape).permit(:location, :keywords, :min_follower_count, :max_follower_count)
  end
end