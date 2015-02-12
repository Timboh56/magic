class PeopleScrapeWorker
  require "resque/errors"
  # extend RetriedJob
  @queue = :people_scrape_worker

  class << self

    def perform(id, action)
      puts id.inspect
      @people_scrape = PeopleScrape.find(id["$oid"])
      @people_scrape.send(action)
    end
  end
end