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
  	current_user.people_scrape.update_attributes!(people_scrape_params)
  	render "shared/success.js"
  end

  def people_scrape_params
  	params.require(:people_scrape).permit(:keywords, :min_follower_count, :max_follower_count)
  end
end