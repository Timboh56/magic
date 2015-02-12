class PeopleScrapeWorker
  require "resque/errors"
  # extend RetriedJob
  @queue = :people_scrape_worker

  class << self

    def perform(id, action)
      puts id.inspect
      @user = PeopleScrape.find(id["$oid"])
      send(action)
    end
  end
end