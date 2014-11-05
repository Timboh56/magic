class Scrape
  include Mongoid::Document
  include Mongoid::Timestamps

  field :URL, :type => String
  field :page_parameterized_url, :type => String
  field :pagination_type, :type => String, :default => "PageLink" # "PageLink" or "URL"
  field :url_parameterization_type, :type => String # "Data" or "Integer"
  field :page_interval, :type => Integer
  field :filename, :type => String
  field :next_selector, :type => String
  field :use_proxies, :type => Boolean, :default => false
  field :last_scanned_url, :type => String
  field :status, :type => String

  has_many :data_sets

  # record set is a "row" of data, scraped from individual page
  has_many :record_sets

  # record list of previously scraped records for use as URL parameters. 
  belongs_to :parameterized_record_list, class_name: "RecordList", autosave: true, inverse_of: :scrapers_used_by
  
  # record list of records created by scrape
  has_one :scraped_record_list, class_name: "RecordList", autosave: true, inverse_of: :created_in_scraper, dependent: :destroy
  
  accepts_nested_attributes_for :data_sets
  before_create :generate_record_list
  validate :check_parameterized_record_list

  def records_count
    scraped_record_list.records_count rescue 0
  end

  def root_data_set
    data_sets.select { |d| !d.link_selector.present? }.first
  end

  def sub_pages_data_sets
    data_sets.select { |d| d.link_selector.present? }
  end

  def open_proxies_csv
    p "Opening proxies csv"

    Dir["proxy_lists/*.csv"].each do |csv_file_path|

      p csv_file_path
      CSV.foreach(csv_file_path) do |row|
        p "csv"
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
    p "Done with proxies csv."
  end

  def run
    open_proxies_csv if use_proxies
    puts id.inspect
    Resque.enqueue(ScraperWorker, id.to_s, last_scanned_url.present?)
  end

  def restart
    open_proxies_csv if use_proxies
    record_sets.destroy_all
    Resque.enqueue(ScraperWorker, id.to_s)
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
          csv << get_csv_data_row(record_set)
        end
      end
    end
  end

  private

  def check_parameterized_record_list
    errors.add(:parameterized_record_list_id, ' must not be nil. ') if url_parameterization_type === "Data" && parameterized_record_list_id.nil?
  end

  def generate_record_list
    record_list = RecordList.new
    record_list.name = filename
    self.scraped_record_list = record_list
  end

end
