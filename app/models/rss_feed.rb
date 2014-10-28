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

	def rss_tweet_no_tag
		response = Feedjira::Feed.fetch_and_parse(url)
		latest_entry = response.entries.first
		"#{ latest_entry.url } #{ latest_entry.title[0,80] }"
	end

	def generate_rss_tweet
		random_tag = (rs = rss_feed_collection.get_random_tag).present? ? "##{ rs.text }" : ""
		"#{ rss_tweet_no_tag } #{ random_tag }"
	end
end