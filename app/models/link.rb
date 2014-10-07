class Link
	include Mongoid::Document

	field :link_selector, type: String
	belongs_to :scrape
	has_many :parameters
	accepts_nested_attributes_for :parameters

	validates_presence_of :link_selector
end