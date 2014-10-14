class Record
	include Mongoid::Document

	field :text, type: String
	validates_presence_of :text

	belongs_to :record_set
	belongs_to :parameter
end