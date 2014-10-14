class Scrape
  include Mongoid::Document
  include Mongoid::Timestamps

  field :URL, :type => String
  field :filename, :type => String
  field :next_selector, :type => String
  has_many :data_sets

  has_many :records
  
  accepts_nested_attributes_for :data_sets

  def root_data_set
    data_sets.select { |d| !d.link_selector.present? }.first
  end

  def sub_pages_data_sets
    data_sets.select { |d| d.link_selector.present? }
  end

	def run
		Resque.enqueue(ScraperWorker, id)
	end

  def get_csv_data_row record_set
    record_set.records.map { |r| r.text }
  end

  def get_csv_header_row parameters
    csv_row = []
    parameters.each do |parameter|
      csv_row.push parameter.name
    end
    csv_row
  end

  def format_to_downloadable_csv

    CSV.generate do |csv|
      data_sets.each do |data_set|

        # header
        csv << get_csv_header_row(data_set.parameters)

        # data
        data_set.record_sets do |record_set|
          csv << get_csv_data_row(record_set)
        end
      end
    end
  end
end
