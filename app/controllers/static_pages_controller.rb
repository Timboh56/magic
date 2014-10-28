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
    @rss_record_set = RecordSet.where(record_set_type: "Rss feeds").first || RecordSet.new(record_set_type: "Rss feeds")
    @rss_feeds = @rss_record_set.records
  end

  def save_rss_feeds
    @rss_record_set = RecordSet.where(record_set_type: "Rss feeds").first || RecordSet.create!(record_set_type: "Rss feeds")

    if params[:rss_feeds]
      params[:rss_feeds].split(",").each do |rss_feed|
        
        record_params = {
          record_set_id: @rss_record_set.id,
          record_type: "Rss",
          text: rss_feed.strip
        }
        
        Record.create!(record_params) unless Record.where(record_params).exists?
      end
      @rss_record_set.save!
    end
  end
end
