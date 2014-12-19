# per user basis
class RssFeedCollection
	include Mongoid::Document
	include Mongoid::Timestamps

	field :name
	field :no_tags, type: Integer, default: 2
	
	belongs_to :user
	has_many :records

	embeds_many :tags
	embeds_many :rss_feeds

	validates_presence_of :user_id

	accepts_nested_attributes_for :rss_feeds
	accepts_nested_attributes_for :tags

	def get_random_tag
		tags[rand(tags.count - 1)]
	end

	def post_from_latest_rss
		rss_feeds.each do |rsf|
			if rsf.has_new_entry?
				rsf.post
				break
			end
		end
		true
	end
end