class RssFeedCollectionsController < ApplicationController
	def index
    if current_user
      @rss_feed_collections = current_user.rss_feed_collections
      @rss_feed_collection = RssFeedCollection.new(user_id: current_user.id)
    end
	end

	def create
    create_or_update
    @message = "Saved!"
    @prev = rss_feed_collections_path
    render "shared/redirect.js"
  end

  def update
    create_or_update
    @message = "Saved!"
  end

  def set_collection
    if params[:id]
      @rss_feed_collection = RssFeedCollection.find(params[:id])
    else
      @rss_feed_collection = RssFeedCollection.new(user_id: current_user.id)
    end
  end

  def destroy
    @id = params[:id]
    RssFeedCollection.find(params[:id]).destroy
  end

  def create_or_update
    set_collection
    rss_feeds = []
    tags = []

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

    @rss_feed_collection.name = params[:rss_feed_collection][:name] if params[:rss_feed_collection][:name]
    @rss_feed_collection.rss_feeds = rss_feeds
    @rss_feed_collection.no_tags = params[:rss_feed_collection][:no_tags]
    @rss_feed_collection.tags = tags
    @rss_feed_collection.save!

  end
end