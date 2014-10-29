class RssFeedCollectionsController < ApplicationController

	def index
    if current_user
      @rss_feed_collections = current_user.rss_feed_collections
      @rss_feed_collection = RssFeedCollection.new(user_id: current_user.id)
    end
	end

	def new


	end

	def create

  end

  private

  def create_or_update
    rss_feeds = []
    tags = []
    if params[:rss_feed_collections]

      unless current_user.rss_feed_collections.present?
        rss_feed_collection = RssFeedCollection.create!(user_id: current_user.id)
      else
        rss_feed_collection = current_user.rss_feed_collections
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

    rss_feed_collection.rss_feeds = rss_feeds
    rss_feed_collection.tags = tags
    rss_feed_collection.save!

    flash[:success] = "Saved."
    redirect_to "/rss_retweeter"
    #render "shared/success"
  end
end