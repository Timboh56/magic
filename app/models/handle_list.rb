class HandleList
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, type: String
  belongs_to :twitter_blast
  has_many :handles, :class_name => "Record"
end