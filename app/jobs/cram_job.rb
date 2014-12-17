class CramJob
  require "mechanize"
  require "pathname"
  require "resque/errors"
  attr_accessor :url, :output_filename
  @queue = :cram_queue

  AGENTS = [
    'Mac Firefox',
    'Mac Safari',
    'Linux Mozilla',
    'Windows IE 6'
  ]
  
  class << self

    def perform(id)
      @craig_cram = CraigCram.find(id)
      @craig_cram.post_to_cities
    end

    def enqueue

      # add scraper class to resque queue
      Resque.enqueue(CramJob, @craig_cram.id)
    end
  end
end