class HandleList
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, type: String
  field :handle_count
  has_many :twitter_blasts
  has_many :handles, :class_name => "Record"

  def handles_limited
  	handles.limit(1000)
  end
end	