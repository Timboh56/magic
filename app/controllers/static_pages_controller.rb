class StaticPagesController < ApplicationController
  before_action :set_static_page, only: [:show, :edit, :update, :destroy]
  layout 'home'
  # GET /static_pages
  # GET /static_pages.json
  def index
    
  end
  def scrape_ape
    @scrape = Scrape.new
    @scrapes = Scrape.all.order("created_at DESC")
  end

  def twitter_blaster
  	@twitter_blast = TwitterBlast.new
  	@twitter_blasts = TwitterBlast.all.order("created_at DESC")
    @handle_lists = HandleList.all
  end

  def craig_crammer

  end

  def rss_retweeter
    if current_user
      @rss_feed_collection = current_user.rss_feed_collection || RssFeedCollection.new(user_id: current_user.id)
      @tags = current_user.rss_feed_collection.tags if current_user.rss_feed_collection.present?
    end
  end

  def save_rss_feeds
    rss_feeds = []
    tags = []
    if params[:rss_feeds]


      unless current_user.rss_feeds.present?
        rss_feed_collection = RssFeedCollection.create!(user_id: current_user.id)
      else
        rss_feed_collection = current_user.rss_feed_collection
      end

      params[:rss_feeds].split(",").each do |rss_feed|
        
        rss_params = {
          url: rss_feed.strip,
        }

        rss_feed = RssFeed.new(rss_params)
        rss_feeds.push(rss_feed)
      end

      params[:tags].split(",").each do |tag|
        tag_params = { text: tag.strip.gsub(" ","_") }
        tags << Tag.new(tag_params) 
      end
    end

    (current_user.rss_feeds - rss_feeds).each do |rss_feed|
      p "Destroying " + rss_feed.inspect
      rss_feed.destroy
    end

    (current_user.tags - tags).each do
      p "Destroying " + tag.inspect
      tag.destroy
    end

    rss_feed_collection.rss_feeds = rss_feeds
    rss_feed_collection.tags = tags
    rss_feed_collection.save!

    flash[:success] = "Saved."
    redirect_to "/rss_retweeter"
    #render "shared/success"
  end
end
