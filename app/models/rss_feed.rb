class RssFeed
	include Mongoid::Document
	include Mongoid::Timestamps

	field :url, type: String
	field :name, type: String

	embedded_in :rss_feed_collection, :inverse_of => :rss_feeds
	validates_presence_of :url

	before_create :get_name

	def user
		rss_feed_collection.user
	end

	def has_new_entry?
		!Record.where(text: rss_tweet_no_tags, record_type: "Tweet").exists?
	end

	def post
		user.tweet(generate_rss_tweet)
		Record.create!(text: rss_tweet_no_tags, rss_feed_collection_id: rss_feed_collection.id, record_type: "Tweet")
	end

	def get_name
		self.name = Feedjira::Feed.fetch_and_parse(url).title
	rescue
		true
	end

	def rss_tweet_no_tags
		@latest_tweet ||=	lambda {
			response = Feedjira::Feed.fetch_and_parse(url)
			latest_entry = response.entries.first
			"#{ latest_entry.title[0,80] } #{ latest_entry.url }"
		}.call
	end

	def generate_rss_tweet
		no_tags = rss_feed_collection.no_tags > rss_feed_collection.tags.count ? rss_feed_collection.tags.count : rss_feed_collection.no_tags
		random_tags = (0..no_tags).inject("") { |str, no|
			random_tag = generate_random_tag
			str += " #{ random_tag }" if str.match(random_tag).nil?
			str
		}
		"#{ rss_tweet_no_tags }#{ random_tags }"
	end

	def generate_random_tag
		random_tag = (rs = rss_feed_collection.get_random_tag).present? ? "##{ rs.text }" : ""
	end
end