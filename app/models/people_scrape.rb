class PeopleScrape
	include Mongoid::Document
	field :keywords, type: String
	field :min_follower_count, type: Integer, default: 0
	field :max_follower_count, type: Integer, default: 10000
	belongs_to :user
	has_many :people
end