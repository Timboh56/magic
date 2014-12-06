class HandleList
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, type: String
  has_many :twitter_blasts
  has_many :handles, :class_name => "Record"

  def handles_limited
  	handles.limit(1000)
  end

  def handles_count
  	handles.count
  end
end	