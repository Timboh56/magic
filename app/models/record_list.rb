class RecordList
  include Mongoid::Document
  include Mongoid::Timestamps
  include Runnable

  field :record_list_type, type: String
  belongs_to :scrape
end