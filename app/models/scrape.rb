class Scrape
  include Mongoid::Document
  include Mongoid::Timestamps

  field :URL, :type => String
  field :page_parameterized_url, :type => String
  field :page_interval, :type => Integer
  field :filename, :type => String
  field :next_selector, :type => String
  field :use_proxies, :type => Boolean, :default => false
  field :last_scanned_url, :type => String
  field :status, :type => String

  has_many :data_sets

  has_many :records
  has_many :record_sets
  
  accepts_nested_attributes_for :data_sets

  def root_data_set
    data_sets.select { |d| !d.link_selector.present? }.first
  end

  def sub_pages_data_sets
    data_sets.select { |d| d.link_selector.present? }
  end

  def open_proxies_csv
    puts "Opening proxies csv"

    Dir["proxy_lists/*.csv"].each do |csv_file_path|

      puts csv_file_path
      CSV.foreach(csv_file_path) do |row|
        puts "csv"
        if row[0].include? ";"
          ip = row[0].split(';')[0]
          port = row[0].split(';')[1]
        else
          ip = row[0].split(':')[0]
          port = row[0].split(':')[1]
        end
        ProxyHost.create!(ip: ip, port: port) unless ProxyHost.where(ip: ip).exists?
      end
    end
    puts "Done with proxies csv."
  end

	def run
    open_proxies_csv
		Resque.enqueue(ScraperWorker, id, last_scanned_url.present?)
	end

  def restart
    open_proxies_csv
    record_sets.destroy_all
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
        data_set.record_sets.order("created_at ASC").each do |record_set|
          puts record_set.inspect
          csv << get_csv_data_row(record_set)
        end
      end
    end
  end
end
