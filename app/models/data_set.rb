class DataSet
	include Mongoid::Document

	field :link_selector, type: String
	has_many :parameters
	has_many :record_sets
	belongs_to :scrape

	accepts_nested_attributes_for :parameters
end