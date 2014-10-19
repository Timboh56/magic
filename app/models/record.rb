class Record
	include Mongoid::Document

	field :text, type: String
	field :record_type, type: String

	validates_presence_of :text

	belongs_to :record_set
	belongs_to :parameter
	belongs_to :scrape
	belongs_to :twitter_blast
end