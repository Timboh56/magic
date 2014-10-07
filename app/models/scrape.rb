class Scrape
  include Mongoid::Document
  include Mongoid::Timestamps

  field :URL, :type => String
  field :filename, :type => String
  field :next_selector, :type => String
  field :records_collected, :type => Integer, :default => 0
  has_many :links
  accepts_nested_attributes_for :links


	def run
		Resque.enqueue(ScraperWorker, id)
	end
end
