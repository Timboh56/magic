class Record
	include Mongoid::Document

	field :text, type: String
	belongs_to :parameter
	validates_presence_of :text
end