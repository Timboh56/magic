class StaticPagesController < ApplicationController
  before_action :set_static_page, only: [:show, :edit, :update, :destroy]
  layout 'home'
  # GET /static_pages
  # GET /static_pages.json
  def index
    @scrape = Scrape.new
    @scrapes = Scrape.all.order("created_at DESC")
  end

  def twitter_blaster
  	@twitter_blast = TwitterBlast.new
  	@twitter_blasts = TwitterBlast.all.order("created_at DESC")
  end
end
