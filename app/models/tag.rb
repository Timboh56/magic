class Tag
	include Mongoid::Document

	field :text

	embedded_in :rss_feed_collection, :inverse_of => :tags
end