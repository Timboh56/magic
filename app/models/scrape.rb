class Scrape
  include Mongoid::Document
  include Mongoid::Timestamps

  field :URL, :type => String
  field :filename, :type => String
  field :next_selector, :type => String
  field :records_collected, :type => Integer, :default => 0
  has_many :links

  # if scraping just one page without crawling additional URLS
  # this object can have many parameters
  has_many :parameters
  
  accepts_nested_attributes_for :links


	def run
		Resque.enqueue(ScraperWorker, id)
	end

  def format_to_downloadable_csv
    csv = CSV.generate do |csv|
      CSV.read("csvs/" + filename.to_s + ".csv").each do |row|
        csv << row
      end
    end
    csv
  end
end
