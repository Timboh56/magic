class RecordSet
	include Mongoid::Document

	belongs_to :data_set
	has_many :records, :dependent => :destroy
end