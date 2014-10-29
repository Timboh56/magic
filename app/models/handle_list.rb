class HandleList
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, type: String
  has_many :twitter_blasts
  has_many :handles, :class_name => "Record"
end