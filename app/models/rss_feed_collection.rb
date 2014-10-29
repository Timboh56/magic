# per user basis
class RssFeedCollection
	include Mongoid::Document
	include Mongoid::Timestamps

	field :name
	
	belongs_to :user
	has_many :records

	embeds_many :tags
	embeds_many :rss_feeds

	accepts_nested_attributes_for :rss_feeds
	accepts_nested_attributes_for :tags

	def get_random_tag
		tags[rand(tags.count - 1)]
	end
end