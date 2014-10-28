class RssFeed
	include Mongoid::Document
	include Mongoid::Timestamps

	field :url, type: String
	field :name, type: String

	embedded_in :rss_feed_collection, :inverse_of => :rss_feeds
	validates_presence_of :url

	before_create :get_name

	def get_name
		self.name = Feedjira::Feed.fetch_and_parse(url).title
	rescue
		true
	end

	def generate_rss_tweet
		response = Feedjira::Feed.fetch_and_parse(url)
		latest_entry = response.entries.first
		random_tag = rss_feed_collection.get_random_tag.text
		" #{ latest_entry.url } #{ latest_entry.title[0,80] } ##{ random_tag }"
	end
end