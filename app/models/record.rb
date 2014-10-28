class Record
	include Mongoid::Document

	field :text, type: String
	field :record_type, type: String

	belongs_to :record_set
	belongs_to :parameter
	belongs_to :scrape
	belongs_to :twitter_blast
	belongs_to :handle_list

	validates_presence_of :text
	validates_uniqueness_of :text, scope: [:record_type]

  scope :handles, lambda { where(record_type: "Handle") }
  scope :rss_feeds, lambda { where(record_type: "Rss") }
end