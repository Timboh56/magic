class StaticPagesController < ApplicationController
  before_action :set_static_page, only: [:show, :edit, :update, :destroy]
  layout 'home'
  # GET /static_pages
  # GET /static_pages.json
  def index
    @scrape = Scrape.new
  end

  def proxy_list

  end

end
