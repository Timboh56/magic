class ScraperWorker
  require "mechanize"
  require "pathname"
  require "resque/errors"
  attr_accessor :url, :output_filename
  @queue = :scraper_queue

  AGENTS = [
    'Mac Firefox',
    'Mac Safari',
    'Linux Mozilla',
    'Windows IE 6'
  ]
  
  class << self


    def perform(id, continue = false, root_url = nil)
      @scrape = Scrape.find(id)
      @scrape.status = "Running.."
      @scrape.save!
      @scrape.init(continue, root_url)
    end

    def enqueue(url)

      puts "Queuing shit up with url: " + url.inspect

      # add scraper class to resque queue
      Resque.enqueue(ScraperWorker, @scrape.id, url)
    end
  end
end