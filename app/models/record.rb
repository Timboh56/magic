class Record
	include Mongoid::Document
	include Mongoid::Timestamps

	field :text, type: String
	field :to, type: String
	
	# "Tweet", "Handle", "Friendship", "DirectMessage" etc
	field :record_type, type: String

	belongs_to :record_set
	belongs_to :parameter
	belongs_to :scrape
	belongs_to :twitter_blast
	belongs_to :handle_list
	belongs_to :rss_feed_collection

	validates_presence_of :text
	validates_uniqueness_of :text, scope: [:record_type]

  scope :handles, lambda { where(record_type: "Handle") }
  scope :follows, lambda { where(record_type: "Friendship") }
  scope :direct_messages, lambda { where(record_type: "DirectMessage") }
end