class RecordList
  include Mongoid::Document
  include Mongoid::Timestamps
  include Runnable

  # "use" or "collect"
  field :record_list_type, type: String

  belongs_to :created_in_scraper, class_name: "Scrape", inverse_of: :scraped_record_list
  has_many :scrapers_used_by, class_name: "Scrape", inverse_of: :parameterized_record_list
end