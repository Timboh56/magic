class ScrapedPage
	include Mongoid::Document

	field :url, type: String
	field :success, type: Boolean
end