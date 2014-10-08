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

  has_many :records
  
  accepts_nested_attributes_for :links
  accepts_nested_attributes_for :parameters


	def run
		Resque.enqueue(ScraperWorker, id)
	end

  def get_csv_data_row parameters
    csv_row = []
    parameters.each do |parameter|
      parameter.records.each do |record|
        csv_row.push record
      end
    end
    csv_row
  end

  def get_csv_header_row parameters
    csv_row = []
    parameters.each do |parameter|
      csv_row.push parameter.name
    end
    csv_row
  end

  def format_to_downloadable_csv
    #csv = CSV.generate do |csv|
    #  CSV.read("csvs/" + filename.to_s + ".csv").each do |row|
    #    csv << row
    #  end
    #end
    #csv

    CSV.generate do |csv|
      csv << get_csv_header_row(parameters)
      csv << get_csv_data_row(parameters)

      # for each link used by scraper,
      # parse to CSV form all parameters
      links.each do |link|
        csv << get_csv_header_row(parameters)
        csv << get_csv_data_row(link.parameters)
      end
    end
  end
end
