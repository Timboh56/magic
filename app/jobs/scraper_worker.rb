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

    rescue Mechanize::ResponseCodeError => r
      if @scrape.use_proxies
        puts "Unable to get to website with IP."
        puts "Proxy with IP " + @current_proxy.ip + " defective, deleting poxy.."
        push_to_defective @current_proxy
      end
      p r.inspect
      save_last_url(@url)
    rescue Timeout::Error => t
      p "Timeout error: " + t.inspect
    rescue Resque::TermException
      Resque.enqueue(self, key)
    rescue Exception => e
      p e.inspect
    end

    def enqueue(url)

      puts "Queuing shit up with url: " + url.inspect

      # add scraper class to resque queue
      Resque.enqueue(ScraperWorker, @scrape.id, url)
    end
  end
end