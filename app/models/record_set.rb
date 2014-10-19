class RecordSet
	include Mongoid::Document
  include Mongoid::Timestamps

	belongs_to :data_set
	belongs_to :scrape
	has_many :records, :dependent => :destroy
end