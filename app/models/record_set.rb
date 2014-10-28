class RecordSet
	include Mongoid::Document
  include Mongoid::Timestamps
  include Runnable

  field :record_set_type, type: String
	belongs_to :data_set
	belongs_to :scrape
end